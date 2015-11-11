require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# List the disks attached to a VM
class Chef::Knife::VsphereVmDiskList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm disk list VMNAME'

  common_options

  def run
    $stdout.sync = true

    unless vmname = @name_args[0]
      show_usage
      fatal_exit 'You must specify a virtual machine name'
    end

    vim = vim_connection
    vm = get_vm(vmname)
    fatal_exit "Could not find #{vmname}" unless vm

    disks = vm.config.hardware.device.select do |device|
      device.is_a? RbVmomi::VIM::VirtualDisk
    end

    disks.each do |disk|
      puts "%3d %20s %0.2fg" % [ disk.unitNumber, disk.deviceInfo.label, disk.capacityInKB/1024/1024]
    end
  end
end
