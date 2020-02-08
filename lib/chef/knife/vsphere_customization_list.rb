#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require_relative "base_vsphere_command"

# Lists all customization specifications in the configured datacenter
# VsphereCustomizationlist extends the BaseVspherecommand
class Chef::Knife::VsphereCustomizationList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere customization list"

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
  end

  common_options

  # The main run method for customization_list
  #
  def run
    $stdout.sync = true

    vim = vim_connection

    csm = vim.serviceContent.customizationSpecManager
    csm.info.each do |c|
      puts "#{ui.color("Customization Name", :cyan)}: #{c.name}"
    end
  end
end
