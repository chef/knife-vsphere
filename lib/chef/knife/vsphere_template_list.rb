#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known VM templates in the configured datacenter
class Chef::Knife::VsphereTemplateList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere template list'

  common_options

  def run
    $stdout.sync = true
    $stderr.sync = true

    vim_connection

    base_folder = find_folder(get_config(:folder))

    vms = find_all_in_folder(base_folder, RbVmomi::VIM::VirtualMachine)
          .select { |v| !v.config.nil? && v.config.template == true }

    vms.each do |vm|
      puts "#{ui.color('Template Name', :cyan)}: #{vm.name}"
    end
  end
end
