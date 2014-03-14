#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# Contributor:: Jesse Campbell (<hikeit@gmail.com>)
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'rbvmomi'

# Base class for vsphere knife commands
class Chef
  class Knife
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

      def self.get_common_options
        unless defined? $default
          $default = Hash.new
        end

        option :vsphere_user,
               :short => "-u USERNAME",
               :long => "--vsuser USERNAME",
               :description => "The username for vsphere"

        option :vsphere_pass,
               :short => "-p PASSWORD",
               :long => "--vspass PASSWORD",
               :description => "The password for vsphere"

        option :vsphere_host,
               :long => "--vshost HOST",
               :description => "The vsphere host"

        option :vsphere_dc,
               :short => "-D DATACENTER",
               :long => "--vsdc DATACENTER",
               :description => "The Datacenter for vsphere"

        option :vsphere_path,
               :long => "--vspath SOAP_PATH",
               :description => "The vsphere SOAP endpoint path"
        $default[:vsphere_path] = "/sdk"

        option :vsphere_port,
               :long => "--vsport PORT",
               :description => "The VI SDK port number to use"
        $default[:vsphere_port] = 443

        option :vshere_nossl,
               :long => "--vsnossl",
               :description => "Disable SSL connectivity"

        option :vsphere_insecure,
               :long => "--vsinsecure",
               :description => "Disable SSL certificate verification"

        option :folder,
               :short => "-f FOLDER",
               :long => "--folder FOLDER",
               :description => "The folder to get VMs from"

        option :proxy_host,
               :long => '--proxyhost PROXY_HOSTNAME',
               :description => 'Proxy hostname'

        option :proxy_port,
               :long => '--proxyport PROXY_PORT',
               :description => 'Proxy port'

        $default[:folder] = ''
      end

      def get_config(key)
        key = key.to_sym
        rval = config[key] || Chef::Config[:knife][key] || $default[key]
        Chef::Log.debug("value for config item #{key}: #{rval}")
        rval
      end

      def get_vim_connection

        conn_opts = {
            :host => get_config(:vsphere_host),
            :path => get_config(:vshere_path),
            :port => get_config(:vsphere_port),
            :use_ssl => !get_config(:vsphere_nossl),
            :user => get_config(:vsphere_user),
            :password => get_config(:vsphere_pass),
            :insecure => get_config(:vsphere_insecure),
            :proxyHost => get_config(:proxy_host),
            :proxyPort => get_config(:proxy_port)
        }

        # Grab the password from the command line
        # if tt is not in the config file
        if not conn_opts[:password]
          conn_opts[:password] = get_password
        end

        #    opt :debug, "Log SOAP messages", :short => 'd', :default => (ENV['RBVMOMI_DEBUG'] || false)

        vim = RbVmomi::VIM.connect conn_opts
        config[:vim] = vim
        return vim
      end

      def get_password
        @password ||= ui.ask("Enter your password: ") { |q| q.echo = false }
      end

      def get_vm(vmname)
        vim = get_vim_connection
        baseFolder = find_folder(get_config(:folder));
        retval = traverse_folders_for_vm(baseFolder, vmname)
        return retval
      end

      def traverse_folders_for_vm(folder, vmname)
        children = folder.children.find_all
        children.each do |child|
          if child.class == RbVmomi::VIM::VirtualMachine && child.name == vmname
              return child
          elsif child.class == RbVmomi::VIM::Folder
            vm = traverse_folders_for_vm(child, vmname)
            if vm then return vm end
          end
        end
        return false
      end

      def traverse_folders_for_dc(folder, dcname)
        children = folder.children.find_all
        children.each do |child|
          if child.class == RbVmomi::VIM::Datacenter && child.name == dcname
            return child
          elsif child.class == RbVmomi::VIM::Folder
            dc = traverse_folders_for_dc(child, dcname)
            if dc then return dc end
          end
        end
        return false
      end

      def get_datacenter
        dcname = get_config(:vsphere_dc)
        traverse_folders_for_dc(config[:vim].rootFolder, dcname) or abort "datacenter not found"
      end

      def find_folder(folderName)
        dc = get_datacenter
        baseEntity = dc.vmFolder
        entityArray = folderName.split('/')
        entityArray.each do |entityArrItem|
          if entityArrItem != ''
            baseEntity = baseEntity.childEntity.grep(RbVmomi::VIM::Folder).find { |f| f.name == entityArrItem } or
                abort "no such folder #{folderName} while looking for #{entityArrItem}"
          end
        end
        baseEntity
      end

      def find_network(networkName)
        dc = get_datacenter
        baseEntity = dc.network
        baseEntity.find { |f| f.name == networkName } or abort "no such network #{networkName}"
      end

      def find_pool(poolName)
        dc = get_datacenter
        baseEntity = dc.hostFolder
        entityArray = poolName.split('/')
        entityArray.each do |entityArrItem|
          if entityArrItem != ''
            if baseEntity.is_a? RbVmomi::VIM::Folder
              baseEntity = baseEntity.childEntity.find { |f| f.name == entityArrItem } or
                  abort "no such pool #{poolName} while looking for #{entityArrItem}"
            elsif baseEntity.is_a? RbVmomi::VIM::ClusterComputeResource or baseEntity.is_a? RbVmomi::VIM::ComputeResource
              baseEntity = baseEntity.resourcePool.resourcePool.find { |f| f.name == entityArrItem } or
                  abort "no such pool #{poolName} while looking for #{entityArrItem}"
            elsif baseEntity.is_a? RbVmomi::VIM::ResourcePool
              baseEntity = baseEntity.resourcePool.find { |f| f.name == entityArrItem } or
                  abort "no such pool #{poolName} while looking for #{entityArrItem}"
            else
              abort "Unexpected Object type encountered #{baseEntity.type} while finding resourcePool"
            end
          end
        end

        baseEntity = baseEntity.resourcePool if not baseEntity.is_a?(RbVmomi::VIM::ResourcePool) and baseEntity.respond_to?(:resourcePool)
        baseEntity
      end

      def choose_datastore(dstores, size)
        vmdk_size_kb = size.to_i * 1024 * 1024
        vmdk_size_B = size.to_i * 1024 * 1024 * 1024

        candidates = []
        dstores.each do |store|
          avail = number_to_human_size(store.summary[:freeSpace])
          cap = number_to_human_size(store.summary[:capacity])
          puts "#{ui.color("Datastore", :cyan)}: #{store.name} (#{avail}(#{store.summary[:freeSpace]}) / #{cap})"

          # vm's can span multiple datastores, so instead of grabbing the first one
          # let's find the first datastore with the available space on a LUN the vm
          # is already using, or use a specified LUN (if given)


          if (store.summary[:freeSpace] - vmdk_size_B) > 0
            # also let's not use more than 90% of total space to save room for snapshots.
            cap_remains = 100 * ((store.summary[:freeSpace].to_f - vmdk_size_B.to_f) / store.summary[:capacity].to_f)
            if (cap_remains.to_i > 10)
              candidates.push(store)
            end
          end
        end
        if candidates.length > 0
          vmdk_datastore = candidates[0]
        else
          puts "Insufficient space on all LUNs designated or assigned to the virtual machine. Please specify a new target."
          vmdk_datastore = nil
        end
        return vmdk_datastore
      end


      def find_datastores_regex(regex)
        stores = Array.new()
        puts "Looking for all datastores that match /#{regex}/"
        dc = get_datacenter
        baseEntity = dc.datastore
        baseEntity.each do |ds|
          if ds.name.match /#{regex}/
            stores.push ds
          end
        end
        return stores
      end

      def find_datastore(dsName)
        dc = get_datacenter
        baseEntity = dc.datastore
        baseEntity.find { |f| f.info.name == dsName } or abort "no such datastore #{dsName}"
      end

      def find_device(vm, deviceName)
        vm.config.hardware.device.each do |device|
          return device if device.deviceInfo.label == deviceName
        end
        nil
      end

      def find_all_in_folder(folder, type)
        if folder.instance_of?(RbVmomi::VIM::ClusterComputeResource) or folder.instance_of?(RbVmomi::VIM::ComputeResource)
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

    end
  end
end
