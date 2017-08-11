#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# migrate vm to specified resource pool , datastore and host
class Chef::Knife::VsphereVmMigrate < Chef::Knife::BaseVsphereCommand
  # migrate --resource-pool --dest-host --dest-datastore
  banner 'knife vsphere vm migrate (options)'

  common_options

  option :dest_host,
         long: '--dest-host HOST',
         description: 'Destination host for the VM or template'

  option :dest_datastore,
         long: '--dest-datastore DATASTORE',
         description: 'The destination datastore'

  option :priority,
         long: '--priority PRIORITY',
         description: 'migration priority'

  option :resource_pool,
         long: '--resource-pool POOL',
         description: 'The resource pool into which to put the VM'

  def find_host_folder(folder, name)
    folder.childEntity.each do |cluster|
      cluster.host.each do |host|
        return host if host.name == name
      end
    end
    nil
  end

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    vim_connection
    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")

    priority = config[:priority]
    dest_host = config[:dest_host]
    ndc = find_datastore(config[:dest_datastore]) || abort('dest-datastore not found')
    pool = find_pool(config[:resource_pool]) if config[:resource_pool]
    dest_host = find_host_folder(dc.hostFolder, dest_host)
    migrate_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(datastore: ndc, pool: pool, host: dest_host)
    vm.RelocateVM_Task(spec: migrate_spec, priority: priority).wait_for_completion
  end
end
