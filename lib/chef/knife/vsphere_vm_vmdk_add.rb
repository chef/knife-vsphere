#
# Author:: Brian Flad (<bflad417@gmail.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known virtual machines in the configured datacenter
class Chef::Knife::VsphereVmVmdkAdd < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vm vmdk add"

  get_common_options

  option :vmdk_type,
         :long => "--vmdk-type TYPE",
         :description => "Type of VMDK"
  # this is a bad idea as it will let you overcommit SAN by 400% or more. thick is a more "sane" default
  $default[:vmdk_type] = "thin"

  option :target_lun,
         :long => "--target-lun NAME",
         :description => "name of target LUN"

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal("You must specify a virtual machine name")
      exit 1
    end

    size = @name_args[1]
    if size.nil?
      ui.fatal "You need a VMDK size!"
      show_usage
      exit 1
    end

    vim = get_vim_connection
    vdm = vim.serviceContent.virtualDiskManager
    vm = get_vm(vmname)
    if vm.nil?
      puts "Could not find #{vmname}"
      return
    end

    target_lun = get_config(:target_lun) unless get_config(:target_lun).nil?
    vmdk_size_kb = size.to_i * 1024 * 1024

    if target_lun.nil?
      vmdk_datastore = choose_datastore(vm.datastore, size)
      exit -1 if vmdk_datastore.nil?
    else
      vmdk_datastores = find_datastores_regex(target_lun)
      vmdk_datastore = choose_datastore(vmdk_datastores, size)
      exit -1 if vmdk_datastore.nil?
      vmdk_dir = "[#{vmdk_datastore.name}] #{vmname}"
      # create the vm folder on the LUN or subsequent operations will fail.
      if not vmdk_datastore.exists? vmname
        dc = get_datacenter
        dc._connection.serviceContent.fileManager.MakeDirectory :name => vmdk_dir, :datacenter => dc, :createParentDirectories => false
      end
    end

    puts "Choosing: #{vmdk_datastore.name}"

    # now we need to inspect the files in this datastore to get our next file name
    next_vmdk = 1
    pc = vmdk_datastore._connection.serviceContent.propertyCollector
    vms = vmdk_datastore.vm
    vmFiles = pc.collectMultiple vms, 'layoutEx.file'
    vmFiles.keys.each do |vm|
      vmFiles[vm]["layoutEx.file"].each do |layout|
        if layout.name.match(/^\[#{vmdk_datastore.name}\] #{vmname}\/#{vmname}_([0-9]+).vmdk/)
          num = $1
          if next_vmdk <= num.to_i
            next_vmdk = num.to_i + 1
          end
        end
      end
    end
    vmdk_fileName = "#{vmname}/#{vmname}_#{next_vmdk}.vmdk"
    vmdk_name = "[#{vmdk_datastore.name}] #{vmdk_fileName}"
    vmdk_type = get_config(:vmdk_type)
    vmdk_type = "preallocated" if vmdk_type == "thick"
    puts "Next vmdk name is => #{vmdk_name}"

    # create the disk
    if not vmdk_datastore.exists? vmdk_fileName
      vmdk_spec = RbVmomi::VIM::FileBackedVirtualDiskSpec(
          :adapterType => "lsiLogic",
          :capacityKb => vmdk_size_kb,
          :diskType => vmdk_type
      )
      ui.info "Creating VMDK"
      ui.info "#{ui.color "Capacity:", :cyan} #{size} GB"
      ui.info "#{ui.color "Disk:", :cyan} #{vmdk_name}"

      if get_config(:noop)
        ui.info "#{ui.color "Skipping disk creation process because --noop specified.", :red}"
      else
        vdm.CreateVirtualDisk_Task(
            :datacenter => get_datacenter,
            :name => vmdk_name,
            :spec => vmdk_spec
        ).wait_for_completion
      end
    end
    ui.info "Attaching VMDK to #{vmname}"

    # now we run through the SCSI controllers to see if there's an available one
    available_controllers = Array.new()
    use_controller = nil
    scsi_tree = Hash.new()
    vm.config.hardware.device.each do |device|
      if device.is_a? RbVmomi::VIM::VirtualSCSIController
        if scsi_tree[device.controllerKey].nil?
          scsi_tree[device.key]=Hash.new()
          scsi_tree[device.key]['children'] = Array.new();
        end
        scsi_tree[device.key]['device'] = device;
      end
      if device.class == RbVmomi::VIM::VirtualDisk
        if scsi_tree[device.controllerKey].nil?
          scsi_tree[device.controllerKey]=Hash.new()
          scsi_tree[device.controllerKey]['children'] = Array.new();
        end
        scsi_tree[device.controllerKey]['children'].push(device)
      end
    end
    scsi_tree.keys.sort.each do |controller|
      if scsi_tree[controller]['children'].length < 15
        available_controllers.push(scsi_tree[controller]['device'].deviceInfo.label)
      end
    end

    if available_controllers.length > 0
      use_controller = available_controllers[0]
      puts "using #{use_controller}"
    else

      if scsi_tree.keys.length < 4

        # Add a controller if none are available
        puts "no controllers available. Will attempt to create"
        new_scsi_key = scsi_tree.keys.sort[scsi_tree.length - 1] + 1
        new_scsi_busNumber = scsi_tree[scsi_tree.keys.sort[scsi_tree.length - 1]]['device'].busNumber + 1

        controller_device = RbVmomi::VIM::VirtualLsiLogicController(
            :key => new_scsi_key,
            :busNumber => new_scsi_busNumber,
            :sharedBus => :noSharing
        )

        device_config_spec = RbVmomi::VIM::VirtualDeviceConfigSpec(
            :device => controller_device,
            :operation => RbVmomi::VIM::VirtualDeviceConfigSpecOperation("add")
        )

        vm_config_spec = RbVmomi::VIM::VirtualMachineConfigSpec(
            :deviceChange => [device_config_spec]
        )

        if get_config(:noop)
          ui.info "#{ui.color "Skipping controller creation process because --noop specified.", :red}"
        else
          vm.ReconfigVM_Task(:spec => vm_config_spec).wait_for_completion
        end
      else
        ui.info "Controllers maxed out at 4."
        exit -1
      end
    end

    # now go back and get the new device's name
    vm.config.hardware.device.each do |device|
      if device.class == RbVmomi::VIM::VirtualLsiLogicController
        if device.key == new_scsi_key
          use_controller = device.deviceInfo.label
        end
      end
    end

    # add the disk
    controller = find_device(vm, use_controller)

    used_unitNumbers = Array.new()
    scsi_tree.keys.sort.each do |c|
      if controller.key == scsi_tree[c]['device'].key
        used_unitNumbers.push(scsi_tree[c]['device'].scsiCtlrUnitNumber)
        scsi_tree[c]['children'].each do |disk|
          used_unitNumbers.push(disk.unitNumber)
        end
      end
    end

    available_unitNumbers = Array.new
    (0 .. 15).each do |scsi_id|
      if used_unitNumbers.grep(scsi_id).length > 0
      else
        available_unitNumbers.push(scsi_id)
      end
    end

    # ensure we don't try to add the controllers SCSI ID
    new_unitNumber = available_unitNumbers.sort[0]
    puts "using SCSI ID #{new_unitNumber}"

    vmdk_backing = RbVmomi::VIM::VirtualDiskFlatVer2BackingInfo(
        :datastore => vmdk_datastore,
        :diskMode => "persistent",
        :fileName => vmdk_name
    )

    device = RbVmomi::VIM::VirtualDisk(
        :backing => vmdk_backing,
        :capacityInKB => vmdk_size_kb,
        :controllerKey => controller.key,
        :key => -1,
        :unitNumber => new_unitNumber
    )

    device_config_spec = RbVmomi::VIM::VirtualDeviceConfigSpec(
        :device => device,
        :operation => RbVmomi::VIM::VirtualDeviceConfigSpecOperation("add")
    )

    vm_config_spec = RbVmomi::VIM::VirtualMachineConfigSpec(
        :deviceChange => [device_config_spec]
    )

    if get_config(:noop)
      ui.info "#{ui.color "Skipping disk attaching process because --noop specified.", :red}"
    else
      vm.ReconfigVM_Task(:spec => vm_config_spec).wait_for_completion
    end
  end
end
