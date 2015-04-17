#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Contributor:: Dennis Pattmann (https://github.com/DennisBP)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known clusters in the configured datacenter
class Chef::Knife::VsphereClusterList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere cluster list'

  common_options

  def traverse_folders(folder)
    return if folder.is_a? RbVmomi::VIM::VirtualApp

    if folder.is_a? RbVmomi::VIM::ClusterComputeResource
      clusters = folder.path[3..-1].reject { |p| p.last == 'ClusterComputeResource' }
      puts "#{ui.color('Cluster', :cyan)}: " + clusters.map(&:last).join('/')
    end

    folders = find_all_in_folder(folder, RbVmomi::VIM::ManagedObject) || []
    folders.each do |child|
      traverse_folders(child)
    end
  end

  def find_cluster_folder(folderName)
    dc = datacenter
    base_entity = dc.hostFolder
    entity_array = folderName.split('/')
    entity_array.each do |entityArrItem|
      if entityArrItem != ''
        base_entity = base_entity.childEntity.grep(RbVmomi::VIM::ManagedObject).find { |f| f.name == entityArrItem } ||
                      abort("no such folder #{folderName} while looking for #{entityArrItem}")
      end
    end
    base_entity
  end

  def run
    vim_connection
    base_folder = find_cluster_folder(get_config(:folder))
    traverse_folders(base_folder)
  end
end
