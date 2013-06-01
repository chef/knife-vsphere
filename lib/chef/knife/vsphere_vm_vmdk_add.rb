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
  $default[:vmdk_type] = "thin"

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

    vmdk_datastore = vm.datastore[0]
    vmdk_fileName = "#{vmname}/#{vmname}_1.vmdk"
    vmdk_name = "[#{vmdk_datastore.name}] #{vmdk_fileName}"
    vmdk_size_kb = size.to_i * 1024 * 1024
    vmdk_type = get_config(:vmdk_type)
    vmdk_type = "preallocated" if vmdk_type == "thick"
    
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
