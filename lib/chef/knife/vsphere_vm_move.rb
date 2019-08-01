#
# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Moves the VM to another folder or datastore
# VsphereVmMove extends the BaseVspherecommand
class Chef::Knife::VsphereVmMove < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm move VMNAME"

  common_options

  option :dest_name,
    long: "--dest-name NAME",
    short: "-r",
    description: "Destination name of the VM or template"

  option :dest_folder,
    long: "--dest-folder FOLDER",
    description: "The destination folder into which the VM or template should be moved"

  option :datastore,
    long: "--datastore STORE",
    description: "The datastore into which to put the cloned VM"

  option :thin_provision,
    long: "--thin-provision",
    description: "Indicates whether disk should be thin provisioned.",
    boolean: true

  option :thick_provision,
    long: "--thick-provision",
    description: "Indicates whether disk should be thick provisioned.",
    boolean: true

  # Convert VM
  #
  # @param [Object] vm The VM object to convert the VM
  def convert_vm(vm)
    dc = datacenter
    hosts = find_all_in_folder(dc.hostFolder, RbVmomi::VIM::ComputeResource)
    rp = hosts.first.resourcePool
    rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(pool: rp)

    if get_config(:thin_provision)
      puts "Thin provsisioning #{vm.name}"
      rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(datastore: find_datastore(get_config(:datastore)), transform: :sparse)
    end

    if get_config(:thick_provision)
      puts "Thick provsisioning #{vm.name}"
      rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(datastore: find_datastore(get_config(:datastore)), transform: :flat)
    end

    task = vm.RelocateVM_Task(spec: rspec)
    task.wait_for_completion
  end

  # Move VM
  #
  # @param [Object] vm The VM object to convert the VM
  def move_vm(vm)
    dest_name = config[:dest_name] || vm.name
    dest_folder = config[:dest_folder].nil? ? (vm.parent) : (find_folder(get_config(:dest_folder)))

    vm.Rename_Task(newName: dest_name).wait_for_completion unless vm.name == dest_name
    dest_folder.MoveIntoFolder_Task(list: [vm]).wait_for_completion unless vm.parent == dest_folder
  end

  # The main run method for vm_move
  #
  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    if get_config(:thin_provision) || get_config(:thick_provision)
      convert_vm(vm)
    else
      move_vm(vm)
    end

    puts "VM #{vm.name} moved successfully"
  end
end
