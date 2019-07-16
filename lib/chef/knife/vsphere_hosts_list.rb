require "chef/knife"
require "chef/knife/base_vsphere_command"
require "rbvmomi"
require "netaddr"

# list hosts belonging to pool
# VsphereHostslist extends the BaseVspherecommand
class Chef::Knife::VsphereHostsList < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere hosts list"

  common_options
  option :pool,
    long: "--pool pool",
    short: "-h",
    description: "Target pool"

  # The main run method for hosts_list
  #
  def run
    vim_connection
    dc = datacenter
    folder = dc.hostFolder

    target_pool = config[:pool]

    pools = find_pools_and_clusters(folder, target_pool)
    if target_pool && pools.empty?
      fatal_exit("Pool #{target_pool} not found")
    end

    pool_list = pools.map do |pool|
      host_list = list_hosts(pool)
      { "Pool" => pool.name, "Hosts" => host_list }
    end
    ui.output(pool_list)
  end

  private

  def list_hosts(pool)
    hosts = pool.host || []
    hosts.map do |hostc|
      { "Host" => hostc.name }
    end
  end
end
