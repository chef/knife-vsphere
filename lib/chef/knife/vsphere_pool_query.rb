require "chef/knife"
require_relative "helpers/base_vsphere_command"

# VspherePoolQuery extends the BaseVsphereCommand
class Chef::Knife::VspherePoolQuery < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere pool query POOLNAME QUERY. See "https://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.ComputeResource.html" for allowed QUERY values.'

  deps do
    Chef::Knife::BaseVsphereCommand.load_deps
    require "netaddr" unless defined?(NetAddr)
  end

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
