#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmNetworkAdd < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm network add VMNAME NETWORKNAME'

  option :adapter_type,
         long: '--adapter-type STRING',
         description: 'Adapter type eg e1000,vmxnet3',
         required: false

  option :mac_address,
         long: '--mac-address STRING',
         description: 'Adapter MAC address eg. AA:BB:CC:DD:EE:FF',
         required: false

  common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    networkname = @name_args[1]
    if networkname.nil?
      show_usage
      fatal_exit('You must specify the network name')
    end

    vim_connection

    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder
    vm = traverse_folders_for_vm(folder, vmname) || abort("VM #{vmname} not found")

    network = find_network(networkname)

    puts network.class
    case network
    when RbVmomi::VIM::DistributedVirtualPortgroup
      switch, pg_key = network.collect 'config.distributedVirtualSwitch', 'key'
      port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
        switchUuid: switch.uuid,
        portgroupKey: pg_key
      )
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo(port: port)
    when VIM::Network
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardNetworkBackingInfo(deviceName: network.name)
    else fail
    end

    adapter_type = ''
    if config[:adapter_type] == 'vmxnet3'
      puts 'Adapter type: vmxnet3'
      adapter_type = 'vmxnet3'
    end
    if config[:adapter_type] == 'e1000'
      adapter_type = 'e1000'
      puts 'Adapter type: e1000'
    end
    if config[:adapter_type].nil?
      puts 'Adapter type: default=vmxnet3'
      adapter_type = 'vmxnet3'
    end

    if config[:mac_address].nil?
      puts 'MAC address: auto'
      mac_address = ''
    else
      mac_address = config[:mac_address]
      puts 'MAC address: ' + mac_address
    end

    case adapter_type
    when 'e1000'
      vm.ReconfigVM_Task(
        spec: {
          deviceChange: [{
            operation: :add,
            fileOperation: nil,
            device: RbVmomi::VIM::VirtualE1000(
              key: -1,
              deviceInfo: { summary: summary, label: '' },
              backing: backing,
              addressType: 'generated',
              macAddress: mac_address
            )
          }]
        }
      ).wait_for_completion
    when 'vmxnet3'
      vm.ReconfigVM_Task(
        spec: {
          deviceChange: [{
            operation: :add,
            fileOperation: nil,
            device: RbVmomi::VIM::VirtualVmxnet3(
              key: -1,
              deviceInfo: { summary: summary, label: '' },
              backing: backing,
              addressType: 'generated',
              macAddress: mac_address
            )
          }]
        }
      ).wait_for_completion
    else
      puts 'Unknown adapter type. Use e1000 or vmxnet3 (default)'
    end
  end
end
