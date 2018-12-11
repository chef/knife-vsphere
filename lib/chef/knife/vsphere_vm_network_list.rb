#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# VsphereVmNetworklist extends the BaseVspherecommand
class Chef::Knife::VsphereVmNetworkList < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm network list VMNAME"

  common_options

  # The main run method for vm_network_list
  #
  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")
    dc = datacenter

    vm.config.hardware.device.each.grep(RbVmomi::VIM::VirtualEthernetCard).map do |nic|
      dc.network.grep(RbVmomi::VIM::DistributedVirtualPortgroup) do |net|
        if nic.backing.port.portgroupKey.eql?(net.key)
          puts "NIC: #{nic.deviceInfo.label} VLAN: #{net.name}"
          break
        end
      end
    end
  end
end
