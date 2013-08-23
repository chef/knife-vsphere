#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'

# Lists all known pools in the configured datacenter
class Chef::Knife::VspherePoolList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere pool list"

  get_common_options

  def traverse_folders(folder)
    puts "#{ui.color("#{folder.class}", :cyan)}: "+(folder.path[3..-1].map { |x| x[1] }.* '/')
    folders = find_all_in_folder(folder, RbVmomi::VIM::ManagedObject)
    unless folders.nil?
      folders.each do |child|
        traverse_folders(child)
      end
    end
  end

  def find_pool_folder(folderName)
    dcname = get_config(:vsphere_dc)
    dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
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
    $stdout.sync = true
    vim = get_vim_connection
    baseFolder = find_pool_folder(get_config(:folder));
    traverse_folders(baseFolder)
  end
end
