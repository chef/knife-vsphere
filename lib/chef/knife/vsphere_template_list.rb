#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'

# Lists all known VM templates in the configured datacenter
class Chef::Knife::VsphereTemplateList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere template list"

  get_common_options
  
  def run

    $stdout.sync = true
    $stderr.sync = true

    vim = get_vim_connection

    dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    
    vmFolders = get_folders(dc.vmFolder)

    vms = find_all_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine).
      select {|v| !v.config.nil? && v.config.template == true }
    
    vms.each do |vm|          
      puts "#{ui.color("Template Name", :cyan)}: #{vm.name}"
    end
  end
end
