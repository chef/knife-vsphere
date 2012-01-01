#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'

# Lists all known virtual machines in the configured datacenter
class Chef::Knife::VsphereVmList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vm list"

  get_common_options
  
  def run

    $stdout.sync = true

    vim = get_vim_connection

    baseFolder = find_folder(config[:folder]);

    vms = find_all_in_folder(baseFolder, RbVmomi::VIM::VirtualMachine)
    vms.each do |vm|
      puts "#{ui.color("VM Name", :cyan)}: #{vm.name}"
    end
  end
end
