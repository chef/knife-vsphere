# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require "chef/knife"
require_relative "helpers/base_vsphere_command"

# VsphereVmShow extends the BaseVspherecommand
class Chef::Knife::VsphereVmShow < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm show VMNAME QUERY. See "https://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html" for allowed QUERY values.'

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
    require_relative "helpers/search_helper"
    include SearchHelper
  end

  common_options

  # The main run method for vm_show
  #
  def run
    $stdout.sync = true
    vmname = @name_args.shift
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    if @name_args.empty?
      show_usage
      fatal_exit("You must specify a QUERY value (e.g. guest.ipAddress or network[0].name)")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    out = @name_args.map do |query_string|
      # split QUERY by dots, and walk the object model
      query = query_string.split "."
      result = vm
      query.each do |part|
        message, index = part.split(/[\[\]]/)
        unless result.respond_to? message.to_sym
          fatal_exit("\"#{query_string}\" not recognized.")
        end
        result = index ? result.send(message)[index.to_i] : result.send(message)
      end

      { query_string => result }
    end
    ui.output out
  end
end
