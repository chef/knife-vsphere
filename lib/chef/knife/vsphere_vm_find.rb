#
# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

PsOn = 'poweredOn'
PsOff = 'poweredOff'
PsSuspended = 'suspended'

# find vms belonging to pool that match criteria, display specified fields
class Chef::Knife::VsphereVmFind < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm find'

  common_options

  option :pool,
         long: '--pool pool',
         short: '-h',
         description: 'Target pool'

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

  option :ram,
         long: '--ram',
         description: 'Show ram'

  option :ip,
         long: '--ip',
         description: 'Show primary ip'

  option :ips,
         long: '--ips',
         description: 'Show all ips, with networks'

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
         description: 'show hostname'

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

  $stdout.sync = true   # smoother output from print

  def traverse_folders_for_pool_clustercompute(folder, poolname)
    # children = folder.children.find_all
    children = find_all_in_folder(folder, RbVmomi::VIM::ManagedObject)
    children.each do |child|
      if child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ResourcePool
        if child.name == poolname then return child
         else if child.class == RbVmomi::VIM::Folder || child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ClusterComputeResource || child.class == RbVmomi::VIM::ResourcePool
                pool = traverse_folders_for_pool_clustercompute(child, poolname)
              end
        end
        if pool then return pool end
      end
    end
    return false
  end

  def run
    poolname = config[:pool]
    if poolname.nil?
      show_usage
      fatal_exit('You must specify a resource pool or cluster name (see knife vsphere pool list)')
    end

    vim = vim_connection
    dc = datacenter
    folder = dc.hostFolder

    pool = traverse_folders_for_pool_clustercompute(folder, poolname) or abort "Pool #{poolname} not found"

    if pool.class == RbVmomi::VIM::ResourcePool
      vm = pool.vm
    else
      vm = pool.resourcePool.vm
    end

    unless vm.nil?
      vm.each do |vmc|
       state = case vmc.runtime.powerState
               when PsOn
                 ui.color('on', :green)
               when PsOff
                 ui.color('off', :red)
               when PsSuspended
                 ui.color('suspended', :yellow)
               end

       if get_config(:matchname)
         next unless vmc.name.include? config[:matchname]
       end

       if get_config(:matchtools)
         next unless vmc.guest.toolsStatus == config[:matchtools]
       end

       next if get_config(:soff) && (vmc.runtime.powerState == PsOn)

       next if get_config(:son) && (vmc.runtime.powerState == PsOff)

       if get_config(:matchip)
         if (!vmc.guest.ipAddress.nil? && vmc.guest.ipAddress != '')
           next unless vmc.guest.ipAddress.include? config[:matchip]
       else
         next
         end
       end

       unless vmc.guest.guestFullName.nil?
         if get_config(:matchos)
           next unless vmc.guest.guestFullName.include? config[:matchos]
         end
       end

       print "#{ui.color("VM Name:", :cyan)} #{vmc.name}\t"
       if get_config(:hostname)
         print "#{ui.color("Hostname:", :cyan)} #{vmc.guest.hostName}\t"
       end

       if get_config(:full_path)
         actualname = ''
         vmcp = vmc
         while vmcp.parent != nil && vmcp.parent.name != 'vm'
           actualname.concat("#{vmcp.parent.name}/")
           vmcp = vmcp.parent
         end
         print "#{ui.color("Folder:", :cyan)}"
         print "\""
         print actualname.split('/').reverse().join('/')
         print "\"\t"

       else
         print "#{ui.color("Folder", :cyan)}: #{vmc.parent.name}\t"
       end

       if get_config(:ip)
         print "#{ui.color("IP:", :cyan)} #{vmc.guest.ipAddress}\t"
       end
       if get_config(:ips)
         ipregex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
         networks = vmc.guest.net.map { |net| "#{net.network}:" + net.ipConfig.ipAddress.select { |i| i.ipAddress[ipregex] }[0].ipAddress }
         print "#{ui.color("IPS:", :cyan)} #{networks.join(",")}\t"
       end
       if get_config(:os)
         print "#{ui.color("OS:", :cyan)} #{vmc.guest.guestFullName}\t"
       end
       if get_config(:ram)
         print "#{ui.color("RAM:", :cyan)} #{vmc.summary.config.memorySizeMB}\t"
       end
       if get_config(:cpu)
         print "#{ui.color("CPU:", :cyan)} #{vmc.summary.config.numCpu}\t"
       end
       if get_config(:alarms)
         print "#{ui.color("Alarms:", :cyan)} #{vmc.summary.overallStatus}\t"
       end
       print "#{ui.color("State:", :cyan)} #{state}\t"
       if get_config(:tools)
         print "#{ui.color("Tools:", :cyan)} #{vmc.guest.toolsStatus}\t"
       end

       if get_config(:os_disk)
         print "#{ui.color("OS Disks:", :cyan)}"
         vmc.guest.disk.each do |disc|
           print "#{disc.diskPath} #{disc.capacity / 1024 / 1024}MB Free:#{disc.freeSpace / 1024 / 1024}MB |"
         end
       end

       if get_config(:esx_disk)
         print "#{ui.color("ESX Disks:", :cyan)}"
         vmc.layout.disk.each do |dsc|
           print "#{dsc.diskFile} | "
         end
       end

       if get_config(:snapshots)
         unless vmc.snapshot.nil?
           print "#{ui.color("Snapshots:", :cyan)}"
           vmc.snapshot.rootSnapshotList.each do |snap|
             print " #{snap.name}"
           end
         end
       end
       puts
      end
    end
  end
end
