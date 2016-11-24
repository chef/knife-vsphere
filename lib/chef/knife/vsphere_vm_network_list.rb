#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

class Chef::Knife::VsphereVmNetworkList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm network list VMNAME'

  common_options

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    vim_connection
    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder
    vm = traverse_folders_for_vm(folder, vmname) || abort("VM #{vmname} not found")


    vm.config.hardware.device.each.grep(RbVmomi::VIM::VirtualEthernetCard) do |a|

      backing = a.backing
      key = a.key


      puts "#{ui.color('NIC', :cyan)}: #{a.deviceInfo.label}"


      #.network.each do |network|
      #  puts "#{ui.color('VLAN', :red)}: #{network.name}"
      #end


    end

  end

  
end
