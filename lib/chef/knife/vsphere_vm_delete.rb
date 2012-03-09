#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'
require 'rbvmomi'

# Delete a virtual machine from vCenter
class Chef::Knife::VsphereVmDelete < Chef::Knife::BaseVsphereCommand

	banner "knife vsphere vm delete VMNAME"

	get_common_options

	def run
		$stdout.sync = true

		vmname = @name_args[0]

		if vmname.nil?
			show_usage
			fatal_exit("You must specify a virtual machine name")
		end

		vim = get_vim_connection

		baseFolder = find_folder(config[:folder]);

		vm = find_in_folder(baseFolder, RbVmomi::VIM::VirtualMachine, vmname) or
		fatal_exit("VM #{vmname} not found")

		vm.PowerOffVM_Task.wait_for_completion unless vm.runtime.powerState == "poweredOff"
		vm.Destroy_Task
		puts "Deleted virtual machine #{vmname}"

	end
end
