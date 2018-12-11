#
# Author:: Owen Groves (<omgroves@gmail.com>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Changes network on a certain VM
# VsphereVmNetworkSet extends the BaseVspherecommand
class Chef::Knife::VsphereVmNetworkSet < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm network set VMNAME NETWORKNAME"

  common_options

  option :nic,
    long: "--nic INTEGER",
    description: "Network interface to use when multiple NICs are present on the VM. (0,1..)",
    default: 0

  # The main run method for vm_network_set
  #
  def run
    $stdout.sync = true
    vmname = @name_args[0]
    networkname = @name_args[1]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end
    if networkname.nil?
      show_usage
      fatal_exit("You must specify a network name")
    end

    network = find_network(networkname)
    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")
    nic = vm.config.hardware.device.each.grep(RbVmomi::VIM::VirtualEthernetCard)[Integer(get_config(:nic))]
    if network.is_a? RbVmomi::VIM::DistributedVirtualPortgroup
      port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(switchUuid: network.config.distributedVirtualSwitch.uuid, portgroupKey: network.key)
      nic.backing = RbVmomi::VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo(port: port)
    elsif network.is_a? RbVmomi::VIM::Network
      nic.backing = RbVmomi::VIM.VirtualEthernetCardNetworkBackingInfo(deviceName: network.name)
    else
      fatal_exit("Network type not recognized")
    end
    change_spec = RbVmomi::VIM.VirtualMachineConfigSpec(deviceChange: [RbVmomi::VIM.VirtualDeviceConfigSpec(device: nic, operation: "edit")])
    vm.ReconfigVM_Task(spec: change_spec).wait_for_completion
  end
end
