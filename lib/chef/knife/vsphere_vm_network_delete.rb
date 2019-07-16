#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

class Chef::Knife::VsphereVmNetworkDelete < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm network delete VMNAME NICNAME"

  common_options

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    nicname = @name_args[1]
    if nicname.nil?
      show_usage
      fatal_exit("You must specify the name of the NIC to delete")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    cards = vm.config.hardware.device.grep(RbVmomi::VIM::VirtualEthernetCard)
    card = cards.detect { |c| c.deviceInfo.label == nicname }
    if card.nil?
      found = cards.map { |c| c.deviceInfo.label }.join ", "
      fatal_exit "Could not find #{nicname}. I did find #{found}."
    else
      spec = RbVmomi::VIM.VirtualMachineConfigSpec(
        deviceChange: [{
          operation: :remove,
          device: card,
        }]
      )

      vm.ReconfigVM_Task(spec: spec).wait_for_completion
      puts "#{ui.color("NIC", :red)}: #{card.deviceInfo.label} was deleted"
    end
  end
end
