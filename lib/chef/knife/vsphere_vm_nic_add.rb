require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmNicAdd < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm nic add VMNAME NETWORKNAME'

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

    backing = RbVmomi::VIM.VirtualEthernetCardNetworkBackingInfo(deviceName: networkname)

    vm.ReconfigVM_Task(spec:
    {
      deviceChange: [
        { operation: :add,
          fileOperation: nil,
          device: RbVmomi::VIM::VirtualVmxnet3(
            key: -1,
            deviceInfo: {
              summary: networkname,
              label: ''
            },
            backing: backing,
            addressType: 'generated'
          )
        }
      ]
    }).wait_for_completion
  end
end
