#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

# find vms belonging to pool that match criteria, display specified fields
class Chef::Knife::VsphereVmFind < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm find'

  common_options

  option :pool,
         long: '--pool pool',
         short: '-h',
         description: 'Target pool'

  option :poolpath,
         long: '--pool-path',
         description: 'Pool is full-path'

  option :esx_disk,
         long: '--esx-disk',
         description: 'Show esx disks'

  option :snapshots,
         long: '--snapshots',
         description: 'Show snapshots'

  option :os_disk,
         long: '--os-disks',
         description: 'Show os disks'

  option :cpu,
         long: '--cpu',
         description: 'Show cpu'

  option :cpu_hot_add_enabled,
         long: '--cpu_hot_add_enabled',
         description: 'Show cpu hot add enabled'

  option :memory_hot_add_enabled,
         long: '--memory_hot_add_enabled',
         description: 'Show memory hot add enabled'

  option :ram,
         long: '--ram',
         description: 'Show ram'

  option :ip,
         long: '--ip',
         description: 'Show primary ip'

  option :ips,
         long: '--ips',
         description: 'Show all ips, with networks - DEPRECATED use --networks'

  option :networks,
         long: '--networks',
         description: 'Show all networks with their IPs'

  option :soff,
         long: '--powered-off',
         description: 'Show only stopped machines'

  option :son,
         long: '--powered-on',
         description: 'Show only started machines'

  option :matchip,
         long: '--match-ip IP',
         description: 'match ip'

  option :matchos,
         long: '--match-os OS',
         description: 'match os'

  option :matchname,
         long: '--match-name VMNAME',
         description: 'match name'

  option :hostname,
         long: '--hostname',
         description: 'show hostname of the guest'

  option :host_name,
         long: '--host_name',
         description: 'show name of the VMs host'

  option :os,
         long: '--os',
         description: 'show os details'

  option :alarms,
         long: '--alarms',
         description: 'show alarm status'

  option :tools,
         long: '--tools',
         description: 'show tools status'

  option :matchtools,
         long: '--match-tools TOOLSSTATE',
         description: 'match tools state'

  option :full_path,
         long: '--full-path',
         description: 'Show full path'

  $stdout.sync = true # smoother output from print

  # Find the given pool or compute resource
  # @param folder [RbVmomi::VIM::Folder] the folder from which to start the search, most likely dc.hostFolder
  # @param objectname [String] name of the object (pool or cluster/compute) to find
  # @return [RbVmomi::VIM::ClusterComputeResource, RbVmomi::VIM::ComputeResource, RbVmomi::VIM::ResourcePool]
  def traverse_folders_for_pool_clustercompute(folder, objectname)
    children = find_all_in_folder(folder, RbVmomi::VIM::ManagedObject)
    children.each do |child|
      next unless child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ResourcePool
      if child.name == objectname
        return child
      elsif child.class == RbVmomi::VIM::Folder || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ResourcePool
        pool = traverse_folders_for_pool_clustercompute(child, objectname)
      end
      return pool if pool
    end
    false
  end

  # Main entry point to the command
  def run
    poolname = config[:pool]
    if poolname.nil?
      show_usage
      fatal_exit('You must specify a resource pool or cluster name (see knife vsphere pool list)')
    end

    abort '--ips has been removed. Please use --networks' if get_config(:ips)

    vim_connection
    dc = datacenter
    folder = dc.hostFolder
    pool = if get_config(:poolpath)
             find_pool(poolname) || abort("Pool #{poolname} not found")
           else
             traverse_folders_for_pool_clustercompute(folder, poolname) || abort("Pool #{poolname} not found")
           end
    vm_list = if pool.class == RbVmomi::VIM::ResourcePool
                pool.vm
              else
                pool.resourcePool.vm
              end

    return if vm_list.nil?

    output = vm_list.map do |vm|
      thisvm = {}
      if get_config(:matchname)
        next unless vm.name.include? config[:matchname]
      end

      if get_config(:matchtools)
        next unless vm.guest.toolsStatus == config[:matchtools]
      end

      power_state = vm.runtime.powerState

      thisvm['state'] = case power_state
                        when PS_ON
                          'on'
                        when PS_OFF
                          'off'
                        when PS_SUSPENDED
                          'suspended'
                        end


      next if get_config(:soff) && (power_state == PS_ON)

      next if get_config(:son) && (power_state == PS_OFF)

      if get_config(:matchip)
        if !vm.guest.ipAddress.nil? && vm.guest.ipAddress != ''
          next unless vm.guest.ipAddress.include? config[:matchip]
        else
          next
        end
      end

      unless vm.guest.guestFullName.nil?
        if get_config(:matchos)
          next unless vm.guest.guestFullName.include? config[:matchos]
        end
      end

      thisvm['name'] = vm.name
      if get_config(:hostname)
        thisvm['hostname'] = vm.guest.hostName
      end
      if get_config(:host_name)
        # TODO: Why vm.summary.runtime vs vm.runtime?
        thisvm['host_name'] = vm.summary.runtime.host.name
      end

      if get_config(:full_path)
        fullpath = ''
        iterator = vm

        while iterator = iterator.parent
          break if iterator.name == 'vm'
          fullpath = fullpath.empty? ? iterator.name : "#{iterator.name}/#{fullpath}"
        end
        thisvm['folder'] = fullpath
      else
        thisvm['folder'] = vm.parent.name
      end

      if get_config(:ip)
        thisvm['ip'] = vm.guest.ipAddress
      end

      if get_config(:networks)
        ipregex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
        thisvm['networks'] = vm.guest.net.map do |net|
          firstip = net.ipConfig.ipAddress.first { |i| i.ipAddress[ipregex] }

          { 'name' => net.network,
            'ip' => firstip.ipAddress,
            'prefix' => firstip.prefixLength
          }
        end
      end

      if get_config(:os)
        thisvm['os'] = vm.guest.guestFullName
      end

      if get_config(:ram)
        thisvm['ram'] = vm.summary.config.memorySizeMB
      end

      if get_config(:cpu_hot_add_enabled)
        thisvm['cpu_hot_add_enabled'] = vm.config.cpuHotAddEnabled
      end

      if get_config(:memory_hot_add_enabled)
        thisvm['memory_hot_add_enabled'] = vm.config.memoryHotAddEnabled
      end

      if get_config(:cpu)
        thisvm['cpu'] = vm.summary.config.numCpu
      end

      if get_config(:alarms)
        thisvm['alarms'] = vm.summary.overallStatus
      end

      if get_config(:tools)
        thisvm['tools'] = vm.guest.toolsStatus
      end

      if get_config(:os_disk)
        thisvm['disks'] = vm.guest.disk.map do |disk|
          { 'name' => disk.diskPath,
            'capacity' => disk.capacity / 1024 / 1024,
            'free' => disk.freeSpace / 1024 / 1024
          }
        end
      end

      if get_config(:esx_disk)
        # TODO: https://www.vmware.com/support/developer/converter-sdk/conv55_apireference/vim.VirtualMachine.html#field_detail says this is deprecated
        thisvm['esx_disks'] = vm.layout.disk.map(&:diskFile)
      end

      if get_config(:snapshots)
        thisvm['snapshots'] = if vm.snapshot
                                vm.snapshot.rootSnapshotList.map(&:name)
                              else
                                []
                              end
      end
      thisvm
    end
    ui.output(output.compact)
  end
end
