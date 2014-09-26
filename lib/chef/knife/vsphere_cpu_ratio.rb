require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereCpuRatio < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere cpu ratio CLUSTER [HOST].'

  get_common_options

  def run
    $stdout.sync = true

    cluster_name = @name_args[0]
    if cluster_name.nil?
      show_usage
      fatal_exit('You must specify a CLUSTER name (e.g. DevCluster )')
    end

    host_name = @name_args[1]

    vim = get_vim_connection

    dc = get_datacenter
    hf = dc.hostFolder
    cluster = hf.childEntity.select { |c| c.name == cluster_name }

    if cluster.length == 0
      fatal_exit("Cluster #{cluster_name} not found.")
    end

    host = host_name.nil? ? cluster[0].host : cluster[0].host.select { |h| h.name == host_name }
    if host.empty?
      fatal_exit('No host found.')
    end

    host.each { |h|
      v_cpu = h.vm.inject(0) { |sum, vm| sum + vm.config.hardware.numCPU }
      p_cpu = h.summary.hardware.numCpuThreads

      ratio = 1.0 * v_cpu/p_cpu

      puts "#{h.name}: #{ratio}"
    }
  end
end
