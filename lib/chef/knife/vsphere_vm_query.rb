require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmQuery < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm query VMNAME QUERY.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html\" for allowed QUERY values."

  common_options

  def run
    args = ARGV
    args[2] = 'show'
    ui.warn 'vsphere vm query is moving to vsphere vm show. Next time, please run'
    ui.warn args.join " "
    Chef::Knife.run(args)
  end
end
