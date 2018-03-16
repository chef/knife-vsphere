# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'chef/knife/search_helper'

# VsphereVMconfig extends the BaseVspherecommand
class Chef::Knife::VsphereVmConfig < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm config VMNAME PROPERTY VALUE.
          See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.vm.ConfigSpec.html\"
          for allowed ATTRIBUTE values (any property of type xs:string is supported)."

  common_options

  # The main run method in vm_config
  #
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

    vm = get_vm_by_name(vmname) || fatal_exit("Could not find #{vmname}")

    properties = {}
    properties[property_name] = property_value
    vm.ReconfigVM_Task(spec: RbVmomi::VIM.VirtualMachineConfigSpec(properties)).wait_for_completion
  end
end
