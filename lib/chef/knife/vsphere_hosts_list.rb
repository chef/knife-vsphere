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

    pools.each do |pool|
      puts "#{ui.color('Pool', :cyan)}: #{pool.name}"
      hosts = pool.host || []
      hosts.each do |hostc|
        puts "  #{ui.color('Host', :cyan)}: #{hostc.name}"
      end
    end
  end
end
