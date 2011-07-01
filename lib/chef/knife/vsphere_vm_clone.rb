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
    class VsphereVmClone < VsphereBaseCommand

      banner "knife vsphere vm clone (options)"

      get_common_options

      option :template,
      :short => "-t TEMPLATE",
      :long => "--template TEMPLATE",
      :description => "The template to create the VM from"
      
      option :vmname,
      :short => "-N VMNAME",
      :long => "--vmname VMNAME",
      :description => "The name for the new virtual machine"

      option :customization_spec,
      :long => "--cspec CUSTOMIZATION_SPEC",
      :description => "The name of any customization specification to apply"

      def run

        $stdout.sync = true
        
        vim = get_vim_connection

        dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
        dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"

        hosts = find_all_in_folders(dc.hostFolder, RbVmomi::VIM::ComputeResource)
        rp = hosts.first.resourcePool

        template = config[:template] or abort "source template name required"
        vmname = config[:vmname] or abort "destination vm name required"

        src_vm = find_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine, template) or
          abort "VM/Template not found"

        rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => rp)

  
        spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec,
                                                    :powerOn => false,
                                                    :template => false)

        if config[:customization_spec]
          cs = find_customization(vim, config[:customization_spec]) or
            abort "failed to find customization specification named #{config[:customization_spec]}"
          spec.customization = cs.spec
        end

        task = src_vm.CloneVM_Task(:folder => src_vm.parent, :name => vmname, :spec => spec)
        puts "Cloning template #{template} to new VM #{vmname}"
        task.wait_for_completion        
        puts "Finished creating virtual machine #{vmname}"

      end

      def find_customization(vim, name) 
        csm = vim.serviceContent.customizationSpecManager
        csm.GetCustomizationSpec(:name => name) 
      end


    end
  end
end
