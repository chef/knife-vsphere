# Author:: Malte Heidenreich
# License:: Apache License, Version 2.0

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Vspherevmtoolsconfig extends the BaseVspherecommand
class Chef::Knife::VsphereVmToolsconfig < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm toolsconfig VMNAME PROPERTY VALUE
          See \"https://www.vmware.com/support/developer/vc-sdk/visdk25pubs/ReferenceGuide/vim.vm.ToolsConfigInfo.html\"
          for available properties and types."

  option :empty,
    short: "-e",
    long: "--empty",
    description: "Allow empty string"
  common_options

  # The main run method for vm_toolsconfig
  #
  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    property = @name_args[1]
    if property.nil?
      show_usage
      fatal_exit("You must specify a property to modify")
    end

    value = @name_args[2]
    if value.nil? && !get_config(:empty)
      show_usage
      fatal_exit("You must specify a value")
    end

    value = "" if get_config(:empty)

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    vm_config_spec = RbVmomi::VIM.VirtualMachineConfigSpec(tools: RbVmomi::VIM.ToolsConfigInfo(property => value))
    vm.ReconfigVM_Task(spec: vm_config_spec)

    puts "property #{property} updated successfully"
  end
end
