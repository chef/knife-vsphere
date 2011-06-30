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

class Chef
  class Knife
    class VsphereVmDelete < VsphereBaseCommand


      banner "knife vsphere vm delete (options)"

      get_common_options
      
      option :vmname,
      :short => "-N VMNAME",
      :long => "--vmname VMNAME",
      :description => "The name of the virtual machine to delete"

      def run

        $stdout.sync = true
        
        vmname = config[:vmname] or abort "virtual machine name required"

        vim = get_vim_connection

        dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
        dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"

        vm = find_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine, vmname) or
          abort "VM not found"

        vm.PowerOffVM_Task.wait_for_completion unless vm.runtime.powerState == "poweredOff"
        vm.UnregisterVM
        puts "Finished unregistering virtual machine #{vmname}"

      end
    end
  end
end
