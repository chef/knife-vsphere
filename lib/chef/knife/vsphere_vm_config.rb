# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require "chef/knife"
require_relative "base_vsphere_command"

# VsphereVMconfig extends the BaseVspherecommand
class Chef::Knife::VsphereVmConfig < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm config VMNAME PROPERTY VALUE (PROPERTY VALUE)...
          See \"https://www.vmware.com/support/developer/converter-sdk/conv60_apireference/vim.vm.ConfigSpec.html\"
          for allowed ATTRIBUTE values (any property of type xs:string is supported)."

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
    require_relative "search_helper"
    include SearchHelper
  end

  common_options

  # The main run method in vm_config
  #
  def run
    $stdout.sync = true
    vmname = @name_args.shift
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    unless @name_args.length > 0 && @name_args.length.even?
      fatal_exit("You must specify a series of PROPERTY name (e.g. annotation) followed by a value")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    properties = @name_args.each_slice(2).map { |prop, val| [prop.to_sym, val] }.to_h
    vm.ReconfigVM_Task(spec: RbVmomi::VIM.VirtualMachineConfigSpec(properties)).wait_for_completion
  end
end
