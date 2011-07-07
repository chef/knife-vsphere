#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'
require 'rbvmomi'
require 'netaddr'

PsOn = 'poweredOn'
PsOff = 'poweredOff'
PsSuspended = 'suspended'

PowerStates = {
  PsOn => 'powered on',
  PsOff => 'powered off',
  PsSuspended => 'suspended'
}

# Manage power state of a virtual machine
class Chef::Knife::VsphereVmState < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vm state VMNAME (options)"

  get_common_options

  option :state,
  :short => "-s STATE",
  :long => "--state STATE",
  :description => "The power state to transition the VM into; one of on|off|suspended"

  def run
  
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal("You must specify a virtual machine name")
      exit 1
    end
   
    vim = get_vim_connection

    dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"

    hosts = find_all_in_folders(dc.hostFolder, RbVmomi::VIM::ComputeResource)
    rp = hosts.first.resourcePool

    vm = find_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine, vmname) or
      abort "VM #{vmname} not found"

    state = vm.runtime.powerState

    if config[:state].nil?
      puts "VM #{vmname} is currently " + PowerStates[vm.runtime.powerState]
    else

      case config[:state]
      when 'on'
        if state == PsOn
          puts "Virtual machine #{vmname} was already powered on"
        else
          vm.PowerOnVM_Task.wait_for_completion
          puts "Powered on virtual machine #{vmname}"
        end
      when 'off'
        if state == PsOff
          puts "Virtual machine #{vmname} was already powered off"
        else
          vm.PowerOffVM_Task.wait_for_completion
          puts "Powered off virtual machine #{vmname}"
        end
      when 'suspend'
        if state == PowerStates['suspended']
          puts "Virtual machine #{vmname} was already suspended"
        else
          vm.SuspendVM_Task.wait_for_completion
          puts "Suspended virtual machine #{vmname}"
        end
      when 'reset'
        vm.ResetVM_Task.wait_for_completion
        puts "Reset virtual machine #{vmname}"
      end
    end
  end
end
