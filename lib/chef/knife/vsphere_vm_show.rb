# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'chef/knife/search_helper'

# VsphereVmShow extends the BaseVspherecommand
class Chef::Knife::VsphereVmShow < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm show VMNAME QUERY.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html\" for allowed QUERY values."

  common_options

  # The main run method for vm_show
  #
  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    query_string = @name_args[1]
    if query_string.nil?
      show_usage
      fatal_exit('You must specify a QUERY value (e.g. guest.ipAddress or network[0].name)')
    end

    vim_connection

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    # split QUERY by dots, and walk the object model
    query = query_string.split '.'
    result = vm
    query.each do |part|
      message, index = part.split(/[\[\]]/)
      unless result.respond_to? message.to_sym
        fatal_exit("\"#{query_string}\" not recognized.")
      end

      result = index ? result.send(message)[index.to_i] : result.send(message)
    end
    puts result
  end
end
