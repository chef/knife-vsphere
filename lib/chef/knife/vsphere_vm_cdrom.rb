# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmCdrom < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm cdrom VMNAME (options)'

  common_options

  option :datastore,
         long: '--datastore STORE',
         description: 'The datastore for an iso source'

  option :iso,
         long: '--iso ISO',
         description: 'The name and path of the ISO to attach'

  option :attach,
         short: '-a',
         long: '--attach',
         description: 'Attach the virtual cdrom to the VM'

  option :disconnect,
         long: '--disconnect',
         description: 'Disconnect the virtual cdrom from the VM'

  option :on_boot,
         long: '--on_boot ONBOOT',
         description: 'False for Detached on boot or True for Attached on boot'

  option :client_device,
         long: '--client_device',
         description: 'Set the backing store to client-device'

  option :recursive,
         short: '-r',
         long: '--recursive',
         description: 'Search all folders'

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal('You must specify a virtual machine name')
      exit 1
    end

    vim_connection

    if get_config(:recursive)
      vms = get_vms(vmname)
      if vms.length > 1
        fatal_exit "More than one VM with name #{vmname} found:\n" + vms.map { |vm| get_path_to_object(vm) }.join("\n")
      end
      fatal_exit "VM #{vmname} not found" if vms.length == 0
      vm = vms[0]
    else
      base_folder = find_folder(get_config(:folder))

      vm = find_in_folder(base_folder, RbVmomi::VIM::VirtualMachine, vmname) || fatal_exit("VM #{vmname} not found")
    end

    if get_config(:iso)
      cdrom_obj = vm.config.hardware.device.find { |hw| hw.class == RbVmomi::VIM::VirtualCdrom }
      fatal_exit 'Could not find a cd drive' unless cdrom_obj

      machine_conf_spec = RbVmomi::VIM::VirtualMachineConfigSpec(
        deviceChange: [{
          operation: :edit,
          device: RbVmomi::VIM::VirtualCdrom(
            backing: RbVmomi::VIM::VirtualCdromIsoBackingInfo(
              fileName: "[#{get_config(:datastore)}] #{get_config(:iso)}"
            ),
            key: cdrom_obj.key,
            controllerKey: cdrom_obj.controllerKey,
            connectable: RbVmomi::VIM::VirtualDeviceConnectInfo(
              startConnected: get_config(:on_boot) || false,
              connected: get_config(:attach) || false,
              allowGuestControl: true
            )
          )
        }]
      )
      vm.ReconfigVM_Task(spec: machine_conf_spec).wait_for_completion
    elsif get_config(:disconnect)
      cdrom_obj = vm.config.hardware.device.find { |hw| hw.class == RbVmomi::VIM::VirtualCdrom }
      fatal_exit 'Could not find a cd drive' unless cdrom_obj

      machine_conf_spec = RbVmomi::VIM::VirtualMachineConfigSpec(
        deviceChange: [{
          operation: :edit,
          device: RbVmomi::VIM::VirtualCdrom(
            backing: RbVmomi::VIM::VirtualCdromRemoteAtapiBackingInfo(
              deviceName: ''),
            key: cdrom_obj.key,
            controllerKey: cdrom_obj.controllerKey,
            connectable: RbVmomi::VIM::VirtualDeviceConnectInfo(
              startConnected: false,
              connected: false,
              allowGuestControl: true
            )
          )
        }]
      )
      vm.ReconfigVM_Task(spec: machine_conf_spec).wait_for_completion
    end
  end
end
