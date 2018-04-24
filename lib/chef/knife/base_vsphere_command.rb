#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# Contributor:: Jesse Campbell (<hikeit@gmail.com>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'rbvmomi'
require 'base64'
require 'filesize'

# Power state on
PS_ON ||= 'poweredOn'.freeze
# Power state off
PS_OFF ||= 'poweredOff'.freeze
# Power state suspended
PS_SUSPENDED ||= 'suspended'.freeze

# Base class for vsphere knife commands
class Chef
  # Base class for knife
  class Knife
    # Main knife vsphere that more or less everything in this gem is built off of
    class BaseVsphereCommand < Knife
      deps do
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
        require 'fog'
        require 'socket'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/json_compat'
      end

      def self.common_options
        option :vsphere_user,
               short: '-u USERNAME',
               long: '--vsuser USERNAME',
               description: 'The username for vsphere'

        option :vsphere_pass,
               short: '-p PASSWORD',
               long: '--vspass PASSWORD',
               description: 'The password for vsphere'

        option :vsphere_host,
               long: '--vshost HOST',
               description: 'The vsphere host'

        option :vsphere_dc,
               short: '-D DATACENTER',
               long: '--vsdc DATACENTER',
               description: 'The Datacenter for vsphere'

        option :vsphere_path,
               long: '--vspath SOAP_PATH',
               description: 'The vsphere SOAP endpoint path',
               default: '/sdk'

        option :vsphere_port,
               long: '--vsport PORT',
               description: 'The VI SDK port number to use',
               default: '443'

        option :vsphere_nossl,
               long: '--vsnossl',
               description: 'Disable SSL connectivity'

        option :vsphere_insecure,
               long: '--vsinsecure',
               description: 'Disable SSL certificate verification'

        option :folder,
               short: '-f FOLDER',
               long: '--folder FOLDER',
               description: 'The folder to get VMs from',
               default: ''

        option :proxy_host,
               long: '--proxyhost PROXY_HOSTNAME',
               description: 'Proxy hostname'

        option :proxy_port,
               long: '--proxyport PROXY_PORT',
               description: 'Proxy port'
      end

      def get_config(key)
        key = key.to_sym
        rval = config[key].nil? ? Chef::Config[:knife][key] : config[key]
        Chef::Log.debug("value for config item #{key}: #{rval}")
        rval
      end

      def password
        if !get_config(:vsphere_pass)
          # Password is not in the config file - grab it
          # from the command line
          get_password_from_stdin
        elsif get_config(:vsphere_pass).start_with?('base64:')
          Base64.decode64(get_config(:vsphere_pass)[7..-1]).chomp
        else
          get_config(:vsphere_pass)
        end
      end

      def conn_opts
        {
          host: get_config(:vsphere_host),
          path: get_config(:vsphere_path),
          port: get_config(:vsphere_port),
          use_ssl: !get_config(:vsphere_nossl),
          user: get_config(:vsphere_user),
          password: password,
          insecure: get_config(:vsphere_insecure),
          proxyHost: get_config(:proxy_host),
          proxyPort: get_config(:proxy_port)
        }
      end

      def vim_connection
        config[:vim] ||= RbVmomi::VIM.connect conn_opts
      end

      def get_password_from_stdin
        @password ||= ui.ask('Enter your password: ') { |q| q.echo = false }
      end

      def traverse_folders_for_pools(folder)
        retval = []
        children = folder.children.find_all
        children.each do |child|
          if child.class == RbVmomi::VIM::ResourcePool
            retval << child
          elsif child.class == RbVmomi::VIM::Folder
            retval.concat(traverse_folders_for_pools(child))
          end
        end
        retval
      end

      def traverse_folders_for_computeresources(folder)
        retval = []
        children = folder.children.find_all
        children.each do |child|
          if child.class == RbVmomi::VIM::ComputeResource || child.class == RbVmomi::VIM::ClusterComputeResource
            retval << child
          elsif child.class == RbVmomi::VIM::Folder
            retval.concat(traverse_folders_for_computeresources(child))
          end
        end
        retval
      end

      def traverse_folders_for_dc(folder, dcname)
        children = folder.children.find_all
        children.each do |child|
          if child.class == RbVmomi::VIM::Datacenter && child.name == dcname
            return child
          elsif child.class == RbVmomi::VIM::Folder
            dc = traverse_folders_for_dc(child, dcname)
            return dc if dc
          end
        end
        false
      end

      def find_pools_and_clusters(folder, poolname = nil)
        pools = traverse_folders_for_pools(folder)
        clusters = traverse_folders_for_computeresources(folder)
        cluster_pool = clusters + pools
        poolname.nil? ? cluster_pool : cluster_pool.select { |p| p.name == poolname }
      end

      def datacenter
        dcname = get_config(:vsphere_dc)
        traverse_folders_for_dc(vim_connection.rootFolder, dcname) || abort('datacenter not found')
      end

      def find_folder(folderName)
        dc = datacenter
        base_entity = dc.vmFolder
        entity_array = folderName.split('/')
        entity_array.each do |entityArrItem|
          if entityArrItem != ''
            base_entity = base_entity.childEntity.grep(RbVmomi::VIM::Folder).find { |f| f.name == entityArrItem } ||
                          abort("no such folder #{folderName} while looking for #{entityArrItem}")
          end
        end
        base_entity
      end

      def find_network(networkName, dvswitch = nil)
        dc = datacenter
        base_entity = dc.network

        networks = base_entity.select { |f| f.name == networkName }
        abort("no such network #{networkName}") if networks.empty?

        if dvswitch && dvswitch != 'auto'
          return networks.find do |f|
            next unless f.respond_to?(:config)
            sw = f.config.distributedVirtualSwitch
            sw.uuid == dvswitch || sw.name == dvswitch
          end
        end

        networks.first
      end

      def find_pool_folder(folderName)
        dc = datacenter
        base_entity = dc.hostFolder
        entity_array = folderName.split('/')
        entity_array.each do |entityArrItem|
          if entityArrItem != ''
            base_entity = base_entity.childEntity.grep(RbVmomi::VIM::ManagedObject).find { |f| f.name == entityArrItem } ||
                          abort("no such folder #{folderName} while looking for #{entityArrItem}")
          end
        end
        base_entity
      end

      def find_pool(poolName)
        dc = datacenter
        base_entity = dc.hostFolder
        entity_array = poolName.split('/')
        entity_array.each do |entityArrItem|
          next if entityArrItem == ''
          if base_entity.is_a? RbVmomi::VIM::Folder
            base_entity = base_entity.childEntity.find { |f| f.name == entityArrItem } ||
                          abort("no such pool #{poolName} while looking for #{entityArrItem}")
          elsif base_entity.is_a?(RbVmomi::VIM::ClusterComputeResource) || base_entity.is_a?(RbVmomi::VIM::ComputeResource)
            base_entity = base_entity.resourcePool.resourcePool.find { |f| f.name == entityArrItem } ||
                          abort("no such pool #{poolName} while looking for #{entityArrItem}")
          elsif base_entity.is_a? RbVmomi::VIM::ResourcePool
            base_entity = base_entity.resourcePool.find { |f| f.name == entityArrItem } ||
                          abort("no such pool #{poolName} while looking for #{entityArrItem}")
          else
            abort "Unexpected Object type encountered #{base_entity.type} while finding resourcePool"
          end
        end

        base_entity = base_entity.resourcePool if !base_entity.is_a?(RbVmomi::VIM::ResourcePool) && base_entity.respond_to?(:resourcePool)
        base_entity
      end

      def find_datastore(dsName)
        dc = datacenter
        base_entity = dc.datastore
        base_entity.find { |f| f.info.name == dsName } || abort("no such datastore #{dsName}")
      end

      def find_datastorecluster(dsName, folder = nil)
        unless folder
          dc = datacenter
          folder = dc.datastoreFolder
        end
        folder.childEntity.each do |child|
          if child.class.to_s == 'Folder'
            ds = find_datastorecluster(dsName, child)
            return ds if ds
          elsif child.class.to_s == 'StoragePod' && child.name == dsName
            return child
          end
        end
        nil
      end

      def number_to_human_size(number)
        number = number.to_f
        storage_units_fmt = %w(byte kB MB GB TB)
        base = 1024
        if number.to_i < base
          unit = storage_units_fmt[0]
        else
          max_exp = storage_units_fmt.size - 1
          exponent = (Math.log(number) / Math.log(base)).to_i # Convert to base
          exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit
          number /= base**exponent
          unit = storage_units_fmt[exponent]
        end

        format('%0.2f %s', number, unit)
      end

      def find_device(vm, deviceName)
        vm.config.hardware.device.each do |device|
          return device if device.deviceInfo.label == deviceName
        end
        nil
      end

      def find_all_in_folder(folder, type)
        if folder.instance_of?(RbVmomi::VIM::ClusterComputeResource) || folder.instance_of?(RbVmomi::VIM::ComputeResource)
          folder = folder.resourcePool
        end
        if folder.instance_of?(RbVmomi::VIM::ResourcePool)
          folder.resourcePool.grep(type)
        elsif folder.instance_of?(RbVmomi::VIM::Folder)
          folder.childEntity.grep(type)
        else
          puts "Unknown type #{folder.class}, not enumerating"
          nil
        end
      end

      def get_path_to_object(object)
        if object.is_a?(RbVmomi::VIM:: ManagedEntity)
          if object.parent.is_a?(RbVmomi::VIM:: ManagedEntity)
            return get_path_to_object(object.parent) + '/' + object.parent.name
          else
            return ''
          end
        else
          puts "Unknown type #{object.class}, not enumerating"
          nil
        end
      end

      def find_in_folder(folder, type, name)
        folder.childEntity.grep(type).find { |o| o.name == name }
      end

      def fatal_exit(msg)
        ui.fatal(msg)
        exit 1
      end

      def tcp_test_port_vm(vm, port)
        ip = vm.guest.ipAddress
        if ip.nil?
          sleep 2
          return false
        end
        tcp_test_port(ip, port)
      end

      def tcp_test_port(hostname, port)
        tcp_socket = TCPSocket.new(hostname, port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}") if port == 22
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def windows?(config)
        is_win_bool = config.guestId.downcase.include?('windows')
        Chef::Log.debug('Identified os as windows.') if is_win_bool
        is_win_bool
      end

      def linux?(config)
        gid = config.guestId.downcase
        # This makes the assumption that if it isn't mac or windows it's linux
        # See https://www.vmware.com/support/developer/vc-sdk/visdk25pubs/ReferenceGuide/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html for values
        is_linux_bool = !gid.include?('windows') && !gid.include?('darwin')
        Chef::Log.debug('Identified os as linux.') if is_linux_bool
        is_linux_bool
      end
    end

    def log_verbose?(level = 1)
      config[:verbosity] >= level
    end
  end
end
