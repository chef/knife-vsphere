# Author:: Raducu Deaconu (<rhadoo_io@yahoo.com>)
# License:: Apache License, Version 2.0
#

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# find vms belonging to pool that match criteria, display specified fields
class Chef::Knife::VsphereVmFind < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm find"

  VMFOLDER ||= "vm".freeze

  common_options

  # Deprecating
  option :pool,
    long: "--pool pool",
    short: "-h",
    description: "Target pool"
  # Deprecating
  option :poolpath,
    long: "--pool-path",
    description: "Pool is full-path"

  option :esx_disk,
    long: "--esx-disk",
    description: "Show esx disks"

  option :snapshots,
    long: "--snapshots",
    description: "Show snapshots"

  option :os_disk,
    long: "--os-disks",
    description: "Show os disks"

  option :cpu,
    long: "--cpu",
    description: "Show cpu"

  option :cpu_hot_add_enabled,
    long: "--cpu_hot_add_enabled",
    description: "Show cpu hot add enabled"

  option :memory_hot_add_enabled,
    long: "--memory_hot_add_enabled",
    description: "Show memory hot add enabled"

  option :ram,
    long: "--ram",
    description: "Show ram"

  option :ip,
    long: "--ip",
    description: "Show primary ip"

  option :networks,
    long: "--networks",
    description: "Show all networks with their IPs"

  option :soff,
    long: "--powered-off",
    description: "Show only stopped machines"

  option :son,
    long: "--powered-on",
    description: "Show only started machines"

  option :matchip,
    long: "--match-ip IP",
    description: "match ip"

  option :matchos,
    long: "--match-os OS",
    description: "match os"

  option :matchname,
    long: "--match-name VMNAME",
    description: "match name"

  option :matchtools,
    long: "--match-tools TOOLSSTATE",
    description: "match tools state"

  option :hostname,
    long: "--hostname",
    description: "show hostname of the guest"

  option :host_name,
    long: "--host_name",
    description: "show name of the VMs host"

  option :os,
    long: "--os",
    description: "show os details"

  option :alarms,
    long: "--alarms",
    description: "show alarm status"

  option :tools,
    long: "--tools",
    description: "show tools status"

  option :full_path,
    long: "--full-path",
    description: "Show full folder path to the VM"

  option :short_path,
    long: "--short-path",
    description: "Show the VM's enclosing folder name"

  $stdout.sync = true # smoother output from print

  # Main entry point to the command
  def run
    property_map("name" => "name")
    property_map("runtime.powerState" => "state") { |value| state_to_english(value) }

    property_map("config.cpuHotAddEnabled" => "cpu_hot_add_enabled") if get_config(:cpu_hot_add_enabled)
    property_map("config.memoryHotAddEnabled" => "memory_hot_add_enabled") if get_config(:memory_hot_add_enabled)
    property_map("guest.guestFullName" => "os") if get_config(:matchos) || get_config(:os)
    property_map("guest.hostName" => "hostname") if get_config(:hostname)
    property_map("guest.ipAddress" => "ip") if get_config(:matchip) || get_config(:ip)
    property_map("guest.toolsStatus" => "tools") if get_config(:matchtools) || get_config(:tools)
    property_map("summary.config.memorySizeMB" => "ram") if get_config(:ram)
    property_map("summary.config.numCpu" => "cpu") if get_config(:cpu)
    property_map("summary.overallStatus" => "alarms") if get_config(:alarms)
    property_map("summary.runtime.host" => "host_name", &:name) if get_config(:host_name)

    # TODO: https://www.vmware.com/support/developer/converter-sdk/conv55_apireference/vim.VirtualMachine.html#field_detail says this is deprecated
    property_map("layout.disk" => "esx_disk") { |disks| disks.map(&:diskFile) } if get_config(:esx_disk)
    property_map("snapshot.rootSnapshotList" => "snapshots") { |snapshots| Array(snapshots).map(&:name) } if get_config(:snapshots)

    if get_config(:networks)
      property_map("guest.net" => "networks") do |nets|
        ipregex = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
        nets.map do |net|
          firstip = net.ipConfig.ipAddress.first { |i| i.ipAddress[ipregex] }
          { "name" => net.network, "ip" => firstip.ipAddress, "prefix" => firstip.prefixLength }
        end
      end
    end

    if get_config(:os_disk)
      property_map("guest.disk" => "disks") do |disks|
        disks.map do |disk|
          { "name" => disk.diskPath,
            "capacity" => disk.capacity / 1024 / 1024,
            "free" => disk.freeSpace / 1024 / 1024 }
        end
      end
    end

    output = matched_vms.map do |vm|
      thisvm = {}
      @output_pairs.each do |property, out_key|
        thisvm[out_key] = if @blocks[out_key]
                            @blocks[out_key].call(vm[property])
                          else
                            vm[property]
                          end
      end

      thisvm["folder"] = full_path_to(vm) if get_config(:full_path)
      thisvm["folder"] = vm.obj.parent.name if get_config(:short_path)

      thisvm
    end
    ui.output(output.compact)
  end

  private

  # property_map sets up the things we'll ask from vmware, and how they'll be displayed
  # If it's passed a Hash then we'll request the key from vmware and the output will appear
  # in the item specified by key.
  # If you pass a block, then the result from vsphere will be passed to the block and that value used instead
  def property_map(property_pair, &block)
    @properties ||= []
    @output_pairs ||= {}
    @blocks ||= {}

    (prop, out_key) = property_pair.first
    @properties << prop
    @output_pairs[prop] = out_key
    @blocks[out_key] = block if block
  end

  def matched_vms
    get_all_vm_objects(properties: @properties).select { |vm| match_vm? vm }
  end

  def match_vm?(vm)
    match_name?(vm["name"]) &&
      match_tools?(vm["guest.toolsStatus"]) &&
      match_power_state?(vm["runtime.powerState"]) &&
      match_ip?(vm["guest.ipAddress"]) &&
      match_os?(vm["guest.guestFullName"])
  end

  def match_name?(name)
    !get_config(:matchname) || name.include?(get_config(:matchname))
  end

  def match_tools?(tools)
    !get_config(:matchtools) || tools == get_config(:matchtools)
  end

  def match_power_state?(power_state)
    !(get_config(:son) || get_config(:soff)) ||
      get_config(:son) && power_state == PS_ON ||
      get_config(:soff) && power_state == PS_OFF
  end

  def match_ip?(ip)
    ip ||= "NOTANIP"
    !get_config(:matchip) || ip.include?(get_config(:matchip))
  end

  def match_os?(os)
    !get_config(:matchos) || (os && os.include?(get_config(:matchos)))
  end

  def state_to_english(power_state)
    case power_state
    when PS_ON
      "on"
    when PS_OFF
      "off"
    when PS_SUSPENDED
      "suspended"
    end
  end

  def full_path_to(vm)
    path = []
    iterator = vm.obj
    while (iterator = iterator.parent)
      break if iterator.name == VMFOLDER

      path.unshift iterator.name
    end

    path.join "/"
  end
end
