#
# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known virtual machines in the configured datacenter
class Chef::Knife::VsphereVmMove < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm move'

  common_options

  option :dest_name,
         long: '--dest-name NAME',
         short: '-r',
         description: 'Destination name of the VM or template'

  option :dest_folder,
         long: '--dest-folder FOLDER',
         description: 'The destination folder into which the VM or template should be moved'

  option :datastore,
         long: '--datastore STORE',
         description: 'The datastore into which to put the cloned VM'

  option :thin_provision,
         long: '--thin-provision',
         description: 'Indicates whether disk should be thin provisioned.',
         boolean: true

  option :thick_provision,
         long: '--thick-provision',
         description: 'Indicates whether disk should be thick provisioned.',
         boolean: true

  # Convert VM
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
  def move_vm(vm)
    dest_name = config[:dest_name] || vmname
    dest_folder = config[:dest_folder].nil? ? (vm.parent) : (find_folder(get_config(:dest_folder)))

    vm.Rename_Task(newName: dest_name).wait_for_completion unless vmname == dest_name
    dest_folder.MoveIntoFolder_Task(list: [vm]).wait_for_completion unless folder == dest_folder
  end

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    vim = vim_connection
    dcname = get_config(:vsphere_dc)
    dc = vim.serviceInstance.find_datacenter(dcname) || abort('datacenter not found')
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")

    if get_config(:thin_provision) || get_config(:thick_provision)
      convert_vm(vm)
    else
      move_vm(vm)
    end
  end
end
