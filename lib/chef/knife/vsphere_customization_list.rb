#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'

# Lists all customization specifications in the configured datacenter
class Chef::Knife::VsphereCustomizationList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere customization list"

  get_common_options

  def run

    $stdout.sync = true

    vim = get_vim_connection

    csm = vim.serviceContent.customizationSpecManager
    csm.info.each do |c|
      puts "#{ui.color("Customization Name", :cyan)}: #{c.name}"

    end

  end
end

