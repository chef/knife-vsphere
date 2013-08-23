# Author:: Ian Delahorne (<ian@delahorne.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmQuery < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm query VMNAME QUERY.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html\" for allowed QUERY values."

  get_common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    query_string = @name_args[1]
    if query_string.nil?
      show_usage
      fatal_exit("You must specify a QUERY value (e.g. guest.ipAddress or network[0].name)")
    end

    vim = get_vim_connection

    dcname = get_config(:vsphere_dc)
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    vm = find_in_folder(folder, RbVmomi::VIM::VirtualMachine, vmname) or
        abort "VM #{vmname} not found"

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
