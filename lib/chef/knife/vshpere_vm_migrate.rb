#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# migrate vm to specified resource pool , datastore and host
class Chef::Knife::VsphereVmMigrate < Chef::Knife::BaseVsphereCommand
#migrate --resource-pool --dest-host --dest-datastore
  banner "knife vsphere vm migrate (options)"

  get_common_options

  option :dest_host,
         :long => "--dest-host HOST",
         :description => "Destination host for the VM or template"

 option :dest_datastore,
         :long => "--dest-datastore DATASTORE",
         :description => "The destination datastore"

 option :priority,
         :long => "--priority PRIORITY",
         :description => "migration priority"

 option :resource_pool,
          :long => "--resource-pool POOL",
        :description => "The resource pool into which to put the VM"



def traverse_folders_for_pool(folder, poolname)
    children = folder.children.find_all
    children.each do |child|
      if child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ResourcePool
        if child.name == poolname then return child end
      elsif child.class == RbVmomi::VIM::Folder
        pool = traverse_folders_for_pool(child, poolname)
        if pool then return pool end
      end
    end
    return false
  end


def find_host_folder(folder, type, name)
folder.host.find { |o| o.name == name }
end

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vim = get_vim_connection
    dc=get_datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) or
        abort "VM #{vmname} not found"


priority=config[:priority]
dest_host=config[:dest_host]
ndc = find_datastore(config[:dest_datastore]) or abort "dest-datastore not found"
npool=find_pool(config[:resource_pool])
folderd = dc.hostFolder
pool = traverse_folders_for_pool(folderd,config[:resource_pool] ) or abort "Pool #{poolname} not found"
h=find_host_folder(pool, RbVmomi::VIM::HostSystem, dest_host)
migrate_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(:datastore => ndc,:pool => npool,:host=>h)
#puts migrate_spec.host.name
vm.RelocateVM_Task(:spec => migrate_spec,:priority=>priority).wait_for_completion


  end
end
