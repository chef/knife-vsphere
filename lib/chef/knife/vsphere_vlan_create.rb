require 'chef/knife'
require 'byebug'
require 'chef/knife/base_vsphere_command'

# Lists all known data stores in datacenter with sizes
class Chef::Knife::VsphereVlanCreate < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vlan create NAME VID'

  common_options

  option :switch,
         long: '--switch DVSNAME',
         description: 'The DVSwitch that will hold this VLAN'

  def run
    $stdout.sync = true

    vim_connection
    net = datacenter.networkFolder

    switches = net.children.select { |n| n.class == RbVmomi::VIM::VmwareDistributedVirtualSwitch }
    switch = if config[:switch]
               switches.find { |s| s.name == config[:switch] }
             else
               ui.warn 'Multiple switches found. Choosing the first switch. Use --switch to select a switch.' if switches.count > 1
               switches.first
             end

    fatal_exit 'No switches found.' if switch.nil?

    ui.info "Found #{switch.name}" if log_verbose?
    switch.AddDVPortgroup_Task(spec: [add_port_spec(@name_args[0], @name_args[1])])
  end

  private

  def add_port_spec(name, vlan_id)
    spec = RbVmomi::VIM::DVPortgroupConfigSpec(
      defaultPortConfig: RbVmomi::VIM::VMwareDVSPortSetting(
        vlan: RbVmomi::VIM::VmwareDistributedVirtualSwitchVlanIdSpec(
          vlanId: vlan_id.to_i,
          inherited: false
        )
      ),
      name: name,
      numPorts: 128,
      type: 'earlyBinding'
    )
    pp spec if log_verbose?
    spec
  end
end
