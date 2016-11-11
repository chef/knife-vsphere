require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmNetworkAdd < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm network add VMNAME NETWORKNAME'

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

    vm.ReconfigVM_Task(
      spec: {
        deviceChange: [{
          operation: :add,
          fileOperation: nil,
          device: RbVmomi::VIM::VirtualVmxnet3(
            key: -1,
            deviceInfo: { summary: summary, label: '' },
            backing: backing,
            addressType: 'generated'
          )
        }]
      }
    ).wait_for_completion
  end
end
