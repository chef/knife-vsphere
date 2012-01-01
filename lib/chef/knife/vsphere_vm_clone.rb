#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/BaseVsphereCommand'
require 'rbvmomi'
require 'netaddr'

# Clone an existing template into a new VM, optionally applying a customization specification.
# 
# usage:
# knife vsphere vm clone NewNode UbuntuTemplate --cspec StaticSpec \
#     --cips 192.168.0.99/24,192.168.1.99/24 \
#     --chostname NODENAME --cdomain NODEDOMAIN
class Chef::Knife::VsphereVmClone < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vm clone VMNAME TEMPLATE (options)"

  get_common_options

	option :dest_folder,
		:long => "--dest_folder FOLDER",
		:description => "The folder into which to put the cloned VM"

	option :resource_pool,
		:long => "--resource_pool RESOURCE_POOL",
		:description => "The resource pool into which to put the cloned VM",
		:default => ''

  option :customization_spec,
  :long => "--cspec CUST_SPEC",
  :description => "The name of any customization specification to apply"

  option :customization_ips,
  :long => "--cips CUST_IPS",
  :description => "Comma-delimited list of CIDR IPs for customization"

  option :customization_hostname,
  :long => "--chostname CUST_HOSTNAME",
  :description => "Unqualified hostname for customization"
 
  option :customization_domain,
  :long => "--cdomain CUST_DOMAIN",
  :description => "Domain name for customization"

  option :customization_tz,
  :long => "--ctz CUST_TIMEZONE",
  :description => "Timezone invalid 'Area/Location' format"

  option :power,  
  :long => "--start STARTVM",
  :description => "Indicates whether to start the VM after a successful clone",
  :default => true



  def run
  
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    template = @name_args[1]
    if template.nil?
      show_usage
      fatal_exit("You must specify a template name")
    end

    vim = get_vim_connection

    src_folder = find_folder(config[:folder])

    src_vm = find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, vmname) or
      abort "VM/Template not found"

    rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => find_pool(config[:resource_pool]))

    if config[:datastore]
      rspec.datastore = find_datastore(config[:datastore])
    end
    
    clone_spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec,
                                                      :powerOn => false,
                                                      :template => false)

    if config[:customization_spec]
      csi = find_customization(vim, config[:customization_spec]) or
        fatal_exit("failed to find customization specification named #{config[:customization_spec]}")

      if csi.info.type != "Linux"
        fatal_exit("Only Linux customization specifications are currently supported")
      end

      if config[:customization_ips]
        csi.spec.nicSettingMap = config[:customization_ips].split(',').map { |i| generate_adapter_map(i) }
      end

      use_ident = !config[:customization_hostname].nil? || !config[:customization_domain].nil?

      if use_ident
        # TODO - verify that we're deploying a linux spec, at least warn
        ident = RbVmomi::VIM.CustomizationLinuxPrep

        if config[:customization_hostname]
          ident.hostName = RbVmomi::VIM.CustomizationFixedName
          ident.hostName.name = config[:customization_hostname]
        else
          ident.hostName = RbVmomi::VIM.CustomizationFixedName
          ident.hostName.name = config[:customization_domain]
        end
        
        if config[:customization_domain]
          ident.domain = config[:customization_domain]
        end
        
        csi.spec.identity = ident
      end

      clone_spec.customization = csi.spec

    end

    dest_folder = find_folder(config[:dest_folder] || config[:folder]);

    task = src_vm.CloneVM_Task(:folder => dest_folder, :name => vmname, :spec => clone_spec)
    puts "Cloning template #{template} to new VM #{vmname}"
    task.wait_for_completion
    puts "Finished creating virtual machine #{vmname}"
    
    if config[:power]
      vm = find_in_folder(dest_folder, RbVmomi::VIM::VirtualMachine, vmname) or
      fatal_exit("VM #{vmname} not found")
      vm.PowerOnVM_Task.wait_for_completion
      puts "Powered on virtual machine #{vmname}"
    end
        
    
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
      # Only set gateway on first IP.
      if config[:customization_ips].split(',').first == ip      
        if gw.nil?
            settings.gateway = [cidr_ip.network(:Objectify => true).next_ip]
        else
          gw_cidr = NetAddr::CIDR.create(gw)
          settings.gateway = [gw_cidr.ip]
        end
      end
    end
    
    adapter_map = RbVmomi::VIM.CustomizationAdapterMapping
    adapter_map.adapter = settings
    adapter_map
   
  end
  
end
