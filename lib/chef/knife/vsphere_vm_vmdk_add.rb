#
# Author:: Brian Flad (<bflad417@gmail.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'

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
    :long => "--target_lun NAME",
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
    vmdk_size_B  = size.to_i * 1024 * 1024 * 1024 

    if target_lun.nil?
      candidates = []
      vm.datastore.each  do |store|
        avail = number_to_human_size(store.summary[:freeSpace])
        cap = number_to_human_size(store.summary[:capacity])                     
        puts "#{ui.color("Datastore", :cyan)}: #{store.name} (#{avail}(#{store.summary[:freeSpace]}) / #{cap})"     

        # vm's can span multiple datastores, so instead of grabbing the first one
        # let's find the first datastore with the available space on a LUN the vm 
        # is already using, or use a specified LUN (if given)

        if ( store.summary[:freeSpace] - vmdk_size_B ) > 0

          # also let's not use more than 90% of total space to save room for snapshots.

          cap_remains = 100 * ( (store.summary[:freeSpace].to_f - vmdk_size_B.to_f ) / store.summary[:capacity].to_f )
          if(cap_remains.to_i > 10)
            candidates.push(store)
          end 
        end
      end
      if candidates.length > 0
        puts "looks like we can put #{size.to_i} in #{candidates.join(" or ")}, using #{candidates[0]}";
        vmdk_datastore = candidates[0]
      else
        puts "Insufficient space on all LUNs currently assigned to #{vmname}. Please specify a new target."
        return 0
      end
    # else
        # we need a get_store method in BaseVsphereCommand
        # vmdk_datastore = target_lun
    end

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

    ui.info "Attaching VMDK to #{vmname}"

    controller = find_device(vm,"SCSI controller 0")

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
      :unitNumber => controller.device.size + 1
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
