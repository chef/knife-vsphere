#
# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known virtual machines in the configured datacenter
class Chef::Knife::VsphereVmMove < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vm move"

  get_common_options

  option :dest_name,
         :long => "--dest-name NAME",
         :short => "-r",
         :description => "Destination name of the VM or template"

  option :dest_folder,
         :long => "--dest-folder FOLDER",
         :description => "The destination folder into which the VM or template should be moved"


  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vim = get_vim_connection
    dcname = get_config(:vsphere_dc)
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) or
        abort "VM #{vmname} not found"

    dest_name = config[:dest_name] || vmname
    dest_folder = config[:dest_folder].nil? ? (vm.parent) : (find_folder(get_config(:dest_folder)))

    vm.Rename_Task(:newName => dest_name).wait_for_completion unless vmname == dest_name
    dest_folder.MoveIntoFolder_Task(:list => [vm]).wait_for_completion unless folder == dest_folder
  end
end
