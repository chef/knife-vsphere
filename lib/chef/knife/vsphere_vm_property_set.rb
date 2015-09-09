# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmPropertySet < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm property set VMNAME PROPERTY VALUE.  Sets a vApp Property on VMNAME.'

  common_options

  option :ovf_environment_transport,
         long: '--ovf-environment-transport STRING',
         description: 'Comma delimited string.  Configures the transports to use for properties. Supported values are: iso and com.vmware.guestInfo.'

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    property_name = @name_args[1]
    if property_name.nil?
      show_usage
      fatal_exit('You must specify a PROPERTY name (e.g. annotation)')
    end
    property_name = property_name.to_sym

    property_value = @name_args[2]
    if property_value.nil?
      show_usage
      fatal_exit('You must specify a PROPERTY value')
    end

    vim_connection

    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")

    if vm.config.vAppConfig && vm.config.vAppConfig.property
      existing_property = vm.config.vAppConfig.property.find { |p| p.props[:id] == property_name.to_s  }
    end

    if existing_property
      operation = 'edit'
      property_key = existing_property.props[:key]
    else
      operation = 'add'
      property_key = property_name.object_id
    end

    vm_config_spec = RbVmomi::VIM.VirtualMachineConfigSpec(
      vAppConfig: RbVmomi::VIM.VmConfigSpec(
        property: [
          RbVmomi::VIM.VAppPropertySpec(
            operation: operation,
            info: {
              key: property_key,
              id: property_name.to_s,
              type: 'string',
              userConfigurable: true,
              value: property_value
            }
          )
        ]
      )
    )

    unless config[:ovf_environment_transport].nil?
      transport = config[:ovf_environment_transport].split(',')
      transport = [''] if transport == [] ## because "".split returns [] and vmware wants [""]
      vm_config_spec[:vAppConfig][:ovfEnvironmentTransport] = transport
    end

    vm.ReconfigVM_Task(spec: vm_config_spec).wait_for_completion
  end
end
