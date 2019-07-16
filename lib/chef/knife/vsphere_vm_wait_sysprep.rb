#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# Contributor:: Malte Heidenreich (https://github.com/mheidenr)
# License:: Apache License, Version 2.0
#

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"
require "chef/knife/customization_helper"

# Wait for vm finishing Sysprep.
# usage:
# knife vsphere vm wait sysprep somemachine --sleep 30 \
#     --timeout 600
class Chef::Knife::VsphereVmWaitSysprep < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  include CustomizationHelper

  banner "knife vsphere vm wait sysprep VMNAME (options)"

  common_options

  option :sleep,
    long: "--sleep TIME",
    description: "The time in seconds to wait between queries for CustomizationSucceeded event. Default: 60 seconds",
    default: 60

  option :timeout,
    long: "--timeout TIME",
    description: "The timeout in seconds before aborting. Default: 300 seconds",
    default: 300

  # The main run method for vm_wait_sysprep.
  #
  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    sleep_time = get_config(:sleep).to_i
    sleep_timeout = get_config(:timeout).to_i

    vim = vim_connection
    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    CustomizationHelper.wait_for_sysprep(vm, vim, sleep_timeout, sleep_time)
  end
end
