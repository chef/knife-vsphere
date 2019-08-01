#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# migrate vm to specified resource pool , datastore and host
class Chef::Knife::VsphereVmMigrate < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  # migrate --resource-pool --dest-host --dest-datastore
  banner "knife vsphere vm migrate VMNAME (options)"

  common_options

  option :dest_host,
    long: "--dest-host HOST",
    description: "Destination host for the VM or template"

  option :dest_datastore,
    long: "--dest-datastore DATASTORE",
    description: "The destination datastore"

  option :priority,
    long: "--priority PRIORITY",
    description: "migration priority"

  option :resource_pool,
    long: "--resource-pool POOL",
    description: "The resource pool into which to put the VM"

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    priority = config[:priority]
    dest_host = get_vm_host_by_name(config[:dest_host]) if config[:dest_host]
    ndc = find_datastore(config[:dest_datastore]) if config[:dest_datastore]
    pool = find_pool(config[:resource_pool]) if config[:resource_pool]

    unless dest_host || ndc || pool
      fatal_exit("You need to specify one or more of --dest-host, --dest-datastore, or --resource-pool")
    end

    migrate_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(datastore: ndc, pool: pool, host: dest_host)
    vm.RelocateVM_Task(spec: migrate_spec, priority: priority).wait_for_completion
  end
end
