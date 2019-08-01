#
# Author:: Malte Heidenreich (https://github.com/mheidenr)
# License:: Apache License, Version 2.0
#

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

class Chef::Knife::VsphereVmDiskExtend < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm disk extend VMNAME SIZE. Extends the disk of vm VMNAME to SIZE kilobytes."

  common_options

  option :diskname,
    long: "--diskname DISKNAME",
    description: "The name of the disk that will be extended"

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    size = @name_args[1]
    if size.nil? || !size.match(/^\d+$/)
      show_usage
      fatal_exit("You must specify the new disk size")
    end

    disk_name = get_config(:diskname) unless get_config(:diskname).nil?

    vim_connection

    dc = datacenter

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    disks = vm.config.hardware.device.select do |device|
      device.is_a?(RbVmomi::VIM::VirtualDisk) && (disk_name.nil? || device.deviceInfo.label == disk_name)
    end

    if disks.length > 1
      names = disks.map { |disk| disk.deviceInfo.label }
      abort("More than 1 disk found: #{names}, please use --diskname DISKNAME")
    elsif disks.length == 0
      abort("No disk found")
    end

    disk = disks[0]
    disk.capacityInKB = size

    vm.ReconfigVM_Task(spec:
      RbVmomi::VIM::VirtualMachineConfigSpec(
        deviceChange: [RbVmomi::VIM::VirtualDeviceConfigSpec(
          device: disk,
          operation: RbVmomi::VIM::VirtualDeviceConfigSpecOperation("edit")
        )]
      )).wait_for_completion

    puts "Disk resized successfully"
  end
end
