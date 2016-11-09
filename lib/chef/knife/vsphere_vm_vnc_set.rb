require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmVncset < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm vncset VMNAME VNCPORT VNCPASSWORD'

  common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    vnc_port = @name_args[1]
    if vnc_port.nil?
      fatal_exit('Specify the port to use for VNC')
    end

    vnc_password = @name_args[2]
    if vnc_password.nil?
      fatal_exit('Specify the password for VNC')
    end

    vim_connection

    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")

    extra_config, = vm.collect('config.extraConfig')

    vm.ReconfigVM_Task(spec: {
      extraConfig: [
        { 
          key: 'RemoteDisplay.vnc.enabled',
          value: 'true' 
        },
        { 
          key: 'RemoteDisplay.vnc.port',
          value: vnc_port.to_s 
        },
        { 
          key: 'RemoteDisplay.vnc.password',
          value: vnc_password.to_s 
        }
      ]
    }).wait_for_completion

    puts extra_config.detect { |x| 'RemoteDisplay.vnc.enabled'.casecmp(x.key) && 'true'.casecmp(x.value.downcase) }
  end
end
