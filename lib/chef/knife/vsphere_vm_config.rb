# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmConfig < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm config VMNAME PROPERTY VALUE.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.vm.ConfigSpec.html\" for allowed ATTRIBUTE values (any property of type xs:string is supported)."

  get_common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    property_name = @name_args[1]
    if property_name.nil?
      show_usage
      fatal_exit("You must specify a PROPERTY name (e.g. annotation)")
    end
    property_name = property_name.to_sym

    property_value = @name_args[2]
    if property_value.nil?
      show_usage
      fatal_exit("You must specify a PROPERTY value")
    end

    vim = get_vim_connection

    dcname = get_config(:vsphere_dc)
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) or
        abort "VM #{vmname} not found"

    properties = {}
    properties[property_name] = property_value
    vm.ReconfigVM_Task(:spec => RbVmomi::VIM.VirtualMachineConfigSpec(properties)).wait_for_completion
  end
end
