require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'
#list hosts belonging to pool
class Chef::Knife::VsphereHostsList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere hosts list"

  get_common_options
  option :pool,
         :long => "--pool pool",
         :short => "-h",
         :description => "Target pool"

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

  def run
    poolname = config[:pool]
    if poolname.nil?
      show_usage
      fatal_exit("You must specify a resource pool or cluster name (see knife vsphere pool list)")
    end


    vim = get_vim_connection
    dc = get_datacenter
    folder = dc.hostFolder

    pool = traverse_folders_for_pool(folder, poolname) or abort "Pool #{poolname} not found"

    hosts=pool.host
     unless hosts.nil?
      hosts.each do |hostc|
      puts "#{ui.color("Host", :cyan)}: #{hostc.name}"
     end
   end
end
end
