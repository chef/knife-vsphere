#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require "chef/knife"
require_relative "helpers/base_vsphere_command"

# Lists all known VM templates in the configured datacenter
# VsphereTemplatelist extends the BaseVspherecommand
class Chef::Knife::VsphereTemplateList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere template list"

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
    require_relative "helpers/search_helper"
    include SearchHelper
  end

  common_options

  # The main run method for template_list
  #
  def run
    $stdout.sync = true
    $stderr.sync = true

    vim_connection

    vms = get_all_vm_objects(
      folder: get_config(:folder),
      properties: ["name", "config.template"]
    ).select { |vm| vm["config.template"] == true }

    vm_list = vms.map do |vm|
      { "Template Name" => vm["name"] }
    end

    ui.output(vm_list)
  end
end
