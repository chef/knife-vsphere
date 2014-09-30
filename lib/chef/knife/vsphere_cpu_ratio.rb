require 'chef/knife'
require 'chef/knife/base_vsphere_command'

class Chef::Knife::VsphereCpuRatio < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere cpu ratio [CLUSTER] [HOST]'

  get_common_options

  def run
    $stdout.sync = true

    cluster_name = @name_args[0]
    host_name = @name_args[1]

    get_vim_connection

    dc = get_datacenter
    hf = dc.hostFolder

    cluster = cluster_name.nil? ? hf.childEntity : hf.childEntity.select { |c| c.name == cluster_name }

    if cluster.empty?
      fatal_exit("Cluster #{cluster_name} not found.")
    end

    cluster.each { |c|
      host = host_name.nil? ? c.host : c.host.select { |h| h.name == host_name }
      if host.empty?
        fatal_exit("Host not found in cluster #{c.name}.")
      end

      puts "### Cluster #{c.name} ###"

      host.each { |h|
        v_cpu = h.vm.inject(0) { |sum, vm| sum + vm.config.hardware.numCPU }
        p_cpu = h.summary.hardware.numCpuThreads

        ratio = 1.0 * v_cpu/p_cpu

        puts "#{h.name}: #{ratio}"
      }
      puts ''
    }
  end
end
