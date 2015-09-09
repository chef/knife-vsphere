#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all vm folders
class Chef::Knife::VsphereFolderList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere folder list'

  common_options

  def traverse_folders(folder, indent_level)
    puts "#{'  ' * indent_level} #{ui.color('Folder', :cyan)}: " + folder.name

    folders = find_all_in_folder(folder, RbVmomi::VIM::Folder)
    folders.each do |child|
      traverse_folders(child, indent_level  + 1)
    end
  end

  def run
    vim_connection
    base_folder = find_folder(get_config(:folder))
    traverse_folders(base_folder, 0)
  end
end
