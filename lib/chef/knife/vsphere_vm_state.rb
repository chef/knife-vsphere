#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/knife'
require 'chef/knife/VsphereBaseCommand'
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

class Chef::Knife::VsphereVmState < Chef::Knife::VsphereBaseCommand

  banner "knife vsphere vm state (options)"

  get_common_options

  option :vmname,
  :short => "-N VMNAME",
  :long => "--vmname VMNAME",
  :description => "The name for the new virtual machine"

  option :state,
  :short => "-s STATE",
  :long => "--state STATE",
  :description => "The power state to transition the VM into; one of on|off|suspended"

  def run
  
    $stdout.sync = true

    vmname = config[:vmname] or abort "destination vm name required"
   
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
