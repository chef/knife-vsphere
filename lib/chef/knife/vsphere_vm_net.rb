#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Switch VM networking state up/down (on all network interfaces)
# VsphereVmNet extends the BaseVspherecommand
class Chef::Knife::VsphereVmNet < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm net STATE VMNAME"
  common_options

  # The main run method for vm_net
  #
  def run
    $stdout.sync = true
    vmname = @name_args[1]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    state = @name_args[0]
    if state.nil?
      show_usage
      fatal_exit("You must specify networking state up/down")
    end

    if state == "up"
      if_state = true
    elsif state == "down"
      if_state = false
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    vm.config.hardware.device.each.grep(RbVmomi::VIM::VirtualEthernetCard) do |a|
      backing = a.backing
      key = a.key

      puts "#{ui.color("Setting network adapter", :cyan)} :#{a.deviceInfo.label} on vlan :#{a.deviceInfo.summary} :#{state}"

      conninfo = RbVmomi::VIM.VirtualDeviceConnectInfo(startConnected: true,
                                                       allowGuestControl: true,
                                                       connected: if_state)

      ndevice = RbVmomi::VIM.VirtualE1000(key: key,
                                          backing: backing,
                                          connectable: conninfo)

      device_spec = RbVmomi::VIM.VirtualDeviceConfigSpec(operation: :edit,
                                                         device: ndevice)

      vmspec = RbVmomi::VIM.VirtualMachineConfigSpec(deviceChange: [device_spec])

      vm.ReconfigVM_Task(spec: vmspec).wait_for_completion
    end
  end
end
