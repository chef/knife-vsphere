#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# Contributor:: Malte Heidenreich (https://github.com/mheidenr)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'chef/knife/customization_helper'

# Wait for vm finishing Sysprep.
# usage:
# knife vsphere vm wait sysprep somemachine --sleep 30 \
#     --timeout 600
class Chef::Knife::VsphereVmWaitSysprep < Chef::Knife::BaseVsphereCommand
  include CustomizationHelper

  banner 'knife vsphere vm wait sysprep VMNAME (options)'

  common_options

  option :sleep,
         long: '--sleep TIME',
         description: 'The time in seconds to wait between queries for CustomizationSucceeded event. Default: 60 seconds',
         default: 60

  option :timeout,
         long: '--timeout TIME',
         description: 'The timeout in seconds before aborting. Default: 300 seconds',
         default: 300

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    config[:vmname] = vmname

    sleep_time = get_config(:sleep).to_i
    sleep_timeout = get_config(:timeout).to_i

    vim = vim_connection
    dc = datacenter

    folder = find_folder(get_config(:folder)) || dc.vmFolder
    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM could not be found in #{folder}")

    CustomizationHelper.wait_for_sysprep(vm, vim, sleep_timeout, sleep_time)
  end
end
