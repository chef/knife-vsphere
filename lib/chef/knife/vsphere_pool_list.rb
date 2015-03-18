#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known pools in the configured datacenter
class Chef::Knife::VspherePoolList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere pool list"

  get_common_options

  def traverse_folders(folder)
    return if folder.is_a? RbVmomi::VIM::VirtualApp

    if folder.is_a? RbVmomi::VIM::ResourcePool
      pools = folder.path[3..-1].reject { |p| p.last == "Resources" }
      puts "#{ui.color("Pool", :cyan)}: " + pools.map(&:last).join('/')
    end

    folders = find_all_in_folder(folder, RbVmomi::VIM::ManagedObject) || []
    folders.each do |child|
      traverse_folders(child)
    end

  end

  def find_pool_folder(folderName)
    dc = get_datacenter
    baseEntity = dc.hostFolder
    entityArray = folderName.split('/')
    entityArray.each do |entityArrItem|
      if entityArrItem != ''
        baseEntity = baseEntity.childEntity.grep(RbVmomi::VIM::ManagedObject).find { |f| f.name == entityArrItem } or
            abort "no such folder #{folderName} while looking for #{entityArrItem}"
      end
    end
    baseEntity
  end

  def run
    vim = get_vim_connection
    baseFolder = find_pool_folder(get_config(:folder));
    traverse_folders(baseFolder)
  end
end
