require 'chef/knife'
require 'chef/knife/base_vsphere_command'

class Chef::Knife::VsphereCpuRatio < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere cpu ratio [CLUSTER] [HOST]'

  common_options

  def run
    $stdout.sync = true

    cluster_name = @name_args[0]
    host_name = @name_args[1]

    vim_connection

    dc = datacenter
    hf = dc.hostFolder

    cluster = cluster_name.nil? ? hf.childEntity : hf.childEntity.select { |c| c.name == cluster_name }

    fatal_exit("Cluster #{cluster_name} not found.") if cluster.empty?

    cluster.each do |c|
      host = host_name.nil? ? c.host : c.host.select { |h| h.name == host_name }
      fatal_exit("Host not found in cluster #{c.name}.") if host.empty?

      puts "### Cluster #{c.name} ###"

      host.each do |h|
        v_cpu = h.vm.inject(0) { |a, e| a + e.config.hardware.numCPU }
        p_cpu = h.summary.hardware.numCpuThreads

        ratio = 1.0 * v_cpu / p_cpu

        puts "#{h.name}: #{ratio}"
      end
      puts ''
    end
  end
end
