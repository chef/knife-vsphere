#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# Contributor:: Jesse Campbell (<hikeit@gmail.com>)
# Contributor:: Bethany Erskine (<bethany@paperlesspost.com>)
# Contributor:: Adrian Stanila (https://github.com/sacx)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'

# Clone an existing template into a new VM, optionally applying a customization specification.
# usage:
# knife vsphere vm markastemplate MyVM --folder /templates
class Chef::Knife::VsphereVmMarkastemplate < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm markastemplate VMNAME'

  common_options

  option :folder,
         long: '--folder FOLDER',
         description: 'The folder which contains the VM'

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end
    config[:chef_node_name] = vmname unless config[:chef_node_name]
    config[:vmname] = vmname

    vim_connection

    dc = datacenter

    src_folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, config[:vmname]) || abort('VM not found')

    puts "Marking VM #{vmname} as template"
    vm.MarkAsTemplate()
    puts "Finished marking VM #{vmname} as template"
  end
end
