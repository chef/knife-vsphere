require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

# list hosts belonging to pool
class Chef::Knife::VsphereHostsList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere hosts list'

  common_options
  option :pool,
         long: '--pool pool',
         short: '-h',
         description: 'Target pool'

  def find_pools(folder, poolname = nil)
    pools = folder.children.find_all.select { |p| p.is_a?(RbVmomi::VIM::ComputeResource) || p.is_a?(RbVmomi::VIM::ResourcePool) }
    poolname.nil? ? pools : pools.select { |p| p.name == poolname }
  end

  def run
    vim_connection
    dc = datacenter
    folder = dc.hostFolder

    target_pool = config[:pool]

    pools = find_pools(folder, target_pool)
    if target_pool && pools.empty?
      puts "Pool #{target_pool} not found"
      return
    end

    pool_list = pools.map do |pool|
      hosts = pool.host || []
      host_list = hosts.map do |hostc|
        { 'Host' => hostc.name }
      end
      { 'Pool' => pool.name,'Hosts' =>host_list }
    end
    ui.output(pool_list)
  end
end
