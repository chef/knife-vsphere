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
  
  option :folder,
  :short => "-f SHOWFOLDER",
  :long => "--folder",
  :description => "The folder to list VMs in"

  def run

    $stdout.sync = true
    
    vim = get_vim_connection


    dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    
    baseFolder = dc.vmFolder;

    if config[:folder]
      baseFolder = get_folders(dc.vmFolder).find { |f| f.name == config[:folder]} or
        abort "no such folder #{config[:folder]}"
    end

    vms = find_all_in_folders(baseFolder, RbVmomi::VIM::VirtualMachine)      
    vms.each do |vm|          
      puts "#{ui.color("VM Name", :cyan)}: #{vm.name}"
    end
  end
end
