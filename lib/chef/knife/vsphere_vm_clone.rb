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

class Chef::Knife::VsphereVmClone < Chef::Knife::VsphereBaseCommand

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

  option :customization_ips,
  :long => "--cips CUSTOMIZATION_IPS",
  :description => "A comma-delimited list of CIDR notation static IPs to be mapped in order for "+
    "any applied customization specification that expects IP addresses"




  def run
  
    $stdout.sync = true

    template = config[:template] or abort "source template name required"
    vmname = config[:vmname] or abort "destination vm name required"
    
    vim = get_vim_connection

    dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
    dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"

    hosts = find_all_in_folders(dc.hostFolder, RbVmomi::VIM::ComputeResource)
    rp = hosts.first.resourcePool

    src_vm = find_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine, template) or
      abort "VM/Template not found"

    rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => rp)

    
    clone_spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec,
                                                      :powerOn => false,
                                                      :template => false)

    if config[:customization_spec]
      csi = find_customization(vim, config[:customization_spec]) or
        abort "failed to find customization specification named #{config[:customization_spec]}"

      if config[:customization_ips]
        csi.spec.nicSettingMap = config[:customization_ips].split(',').map { |i| generate_adapter_map(i) }
      end

      clone_spec.customization = csi.spec

    end

    task = src_vm.CloneVM_Task(:folder => src_vm.parent, :name => vmname, :spec => clone_spec)
    puts "Cloning template #{template} to new VM #{vmname}"
    task.wait_for_completion        
    puts "Finished creating virtual machine #{vmname}"
  end
  

  # Retrieves a CustomizationSpecItem that matches the supplied name
  # @param vim [Connection] VI Connection to use
  # @param name [String] name of customization
  # @return [RbVmomi::VIM::CustomizationSpecItem]
  def find_customization(vim, name) 
    csm = vim.serviceContent.customizationSpecManager
    csm.GetCustomizationSpec(:name => name) 
  end
  
  # Generates a CustomizationAdapterMapping (currently only single IPv4 address) object
  # @param ip [String] Any static IP address to use, otherwise DHCP
  # @param gw [String] If static, the gateway for the interface, otherwise network address + 1 will be used
  # @return [RbVmomi::VIM::CustomizationIPSettings]
  def generate_adapter_map (ip=nil, gw=nil, dns1=nil, dns2=nil, domain=nil)
           
    settings = RbVmomi::VIM.CustomizationIPSettings

    if ip.nil?
      settings.ip = RbVmomi::VIM::CustomizationDhcpIpGenerator
    else
      cidr_ip = NetAddr::CIDR.create(ip)
      settings.ip = RbVmomi::VIM::CustomizationFixedIp(:ipAddress => cidr_ip.ip)
      settings.subnetMask = cidr_ip.netmask_ext

      # TODO - want to confirm gw/ip are in same subnet?
      if [gw.nil?]
        settings.gateway = [cidr_ip.network(:Objectify => true).next_ip]
      else
        gw_cidr = NetAddr::CIDR.create(gw)
        settings.gateway = [gw_cidr.ip]
      end
    end
    
    adapter_map = RbVmomi::VIM.CustomizationAdapterMapping
    adapter_map.adapter = settings
    adapter_map
    #end
  end
  
end
