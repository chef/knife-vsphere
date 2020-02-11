require "chef/knife"
require_relative "base_vsphere_command"

# List the disks attached to a VM
# VsphereVmdisklist extends the BaseVspherecommand
class Chef::Knife::VsphereVmDiskList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm disk list VMNAME"

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
    require_relative "search_helper"
    include SearchHelper
  end

  common_options

  # The main run method for vm_disk_list
  #
  def run
    $stdout.sync = true

    unless vmname = @name_args[0]
      show_usage
      fatal_exit "You must specify a virtual machine name"
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    disks = vm.config.hardware.device.select do |device|
      device.is_a? RbVmomi::VIM::VirtualDisk
    end

    disks.each do |disk|
      puts "%3d %20s %20s %s" % [disk.unitNumber,
                            disk.deviceInfo.label,
                            disk.backing.datastore.name,
                            Filesize.from("#{disk.capacityInKB} KiB").pretty]
    end
  end
end
