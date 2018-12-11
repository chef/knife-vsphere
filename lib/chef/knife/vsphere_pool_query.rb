require "chef/knife"
require "chef/knife/base_vsphere_command"
require "rbvmomi"
require "netaddr"

# VspherePoolQuery extends the BaseVsphereCommand
class Chef::Knife::VspherePoolQuery < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere pool query POOLNAME QUERY.  See "http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.ComputeResource.html" for allowed QUERY values.'

  common_options

  # The main run method for poll_query
  #
  def run
    args = ARGV
    args[2] = "show"
    ui.warn "vsphere pool query is moving to vsphere pool show. Next time, please run"
    ui.warn args.join " "
    Chef::Knife.run(args)
  end
end
