require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VspherePoolQuery < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere pool query POOLNAME QUERY.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.ComputeResource.html\" for allowed QUERY values."

  common_options

  def traverse_folders_for_pool(folder, poolname)
    children = folder.children.find_all
    children.each do |child|
      if child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ResourcePool
        return child if child.name == poolname
      elsif child.class == RbVmomi::VIM::Folder
        pool = traverse_folders_for_pool(child, poolname)
        return pool if pool
      end
    end
    false
  end

  def run
    $stdout.sync = true
    poolname = @name_args[0]
    if poolname.nil?
      show_usage
      fatal_exit('You must specify a resource poor or cluster name (see knife vsphere pool list)')
    end

    query_string = @name_args[1]
    if query_string.nil?
      show_usage
      fatal_exit('You must specify a QUERY value (e.g. summary.overallStatus )')
    end

    vim_connection

    dc = datacenter
    folder = dc.hostFolder

    pool = traverse_folders_for_pool(folder, poolname) || abort("Pool #{poolname} not found")

    # split QUERY by dots, and walk the object model
    query = query_string.split '.'
    result = pool
    query.each do |part|
      message, index = part.split(/[\[\]]/)
      unless result.respond_to? message.to_sym
        fatal_exit("\"#{query_string}\" not recognized.")
      end

      result = index ? result.send(message)[index.to_i] : result.send(message)
    end
    puts result
  end
end
