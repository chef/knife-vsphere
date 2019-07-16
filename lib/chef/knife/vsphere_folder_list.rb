#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"

# Lists all vm folders
# VsphereFolderlist extends the BaseVspherecommand
class Chef::Knife::VsphereFolderList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere folder list"

  common_options

  # Walks though the folders to find something
  #
  # param [String] folder that you should go through
  # param [String] indent_level for the output to indent
  def traverse_folders(folder, indent_level)
    puts "#{"  " * indent_level} #{ui.color("Folder", :cyan)}: " + folder.name

    folders = find_all_in_folder(folder, RbVmomi::VIM::Folder)
    folders.each do |child|
      traverse_folders(child, indent_level + 1)
    end
  end

  # Main run method for folder_list
  def run
    vim_connection
    base_folder = find_folder(get_config(:folder))
    traverse_folders(base_folder, 0)
  end
end
