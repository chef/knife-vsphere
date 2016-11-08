# Author:: Brian Dupras (<bdupras@rallydev.com>)
# License:: Apache License, Version 2.0

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'


class Chef::Knife::VsphereVmShow < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere vm show VMNAME QUERY.  See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html\" for allowed QUERY values."

  common_options

  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit('You must specify a virtual machine name')
    end

    query_string = @name_args[1]
    if query_string.nil?
      show_usage
      fatal_exit('You must specify a QUERY value (e.g. guest.ipAddress or network[0].name)')
    end

    vim_connection

    dc = datacenter
    folder = find_folder(get_config(:folder)) || dc.vmFolder

    #vm = traverse_folders_for_vm(folder, vmname) || abort("VM #{vmname} not found")





	network = find_network(options["net"])

    puts network.class
    case network
    when RbVmomi::VIM::DistributedVirtualPortgroup
      switch, pg_key = network.collect 'config.distributedVirtualSwitch', 'key'
      port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
        switchUuid: switch.uuid,
        portgroupKey: pg_key)
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo(port: port)
    when VIM::Network
      summary = network.name
      backing = RbVmomi::VIM.VirtualEthernetCardNetworkBackingInfo(deviceName: network.name)
    else fail
    end

    vm = find_by_name(vmname)

    vm.ReconfigVM_Task(spec: { 
      deviceChange: [
        { operation: :add,
          fileOperation: nil,
          device: RbVmomi::VIM::VirtualVmxnet3(
            key: -1,
            deviceInfo: {
              summary: summary,
              label: ""
            },
            backing: backing,
            addressType: "generated"
          )
      }
      ]}).wait_for_completion






  end


  private

  def vim
    @vim ||= RbVmomi::VIM.connect host: '10.4.17.49', user: 'administrator@vsphere.local', password: 'QW@#23qw', insecure: true
  end

  def dc
    @dc ||= vim.serviceInstance.find_datacenter(options["dc"]) or fail "datacenter not found"
  end

  def networks
    @networks ||= dc.networkFolder.childEntity
  end

  def find_network(name)
    networks.find { |n| n.name == name }
  end

  def find_by_name(name)
    @vm ||= begin
              folder = dc.vmFolder
              all_vms = vms(folder)
              all_vms.find { |vm| vm.name == name }
            end
    raise "can't find #{name}" unless @vm
    @vm
  end

  def vms(folder) # recursively go thru a folder, dumping vm info
    folder.childEntity.flat_map do |obj|
      name, junk = obj.to_s.split('(')
      case name
      when "Folder"
        vms(obj)
      when "VirtualMachine"
        obj
      end
    end.reject(&:nil?)
  end


end
