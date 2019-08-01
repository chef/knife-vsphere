#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"
require "netaddr"

class Chef::Knife::VsphereVmNetworkAdd < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm network add VMNAME NETWORKNAME"

  option :adapter_type,
    long: "--adapter-type STRING",
    description: "Adapter type eg e1000,vmxnet3",
    required: true

  option :mac_address,
    long: "--mac-address STRING",
    description: "Adapter MAC address eg. AA:BB:CC:DD:EE:FF",
    required: false

  common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    networkname = @name_args[1]
    if networkname.nil?
      show_usage
      fatal_exit("You must specify the network name")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    network = find_network(networkname)

    case network
    when RbVmomi::VIM::DistributedVirtualPortgroup
      switch, pg_key = network.collect "config.distributedVirtualSwitch", "key"
      port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
        switchUuid: switch.uuid,
        portgroupKey: pg_key
      )
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo(port: port)
    when RbVmomi::VIM::Network
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardNetworkBackingInfo(deviceName: network.name)
    else raise
    end

    device_type = case get_config(:adapter_type)
    when "e1000"
      :VirtualE1000
    when "vmxnet3"
      :VirtualVmxnet3
    when *
      fatal_exit("The adapter must be either e1000 or vmxnet3")
                  end

    if get_config(:mac_address).nil?
      address_type = "generated"
      mac_address = ""
    else
      address_type = "manual"
      mac_address = get_config(:mac_address)
    end

    vm.ReconfigVM_Task(
      spec: {
        deviceChange: [{
          operation: :add,
          fileOperation: nil,
          device: RbVmomi::VIM.send(device_type,
            key: -1,
            deviceInfo: { summary: summary, label: "" },
            backing: backing,
            addressType: address_type,
            macAddress: mac_address),
        }],
      }
    ).wait_for_completion
  end
end
