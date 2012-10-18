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
					:short => "-d DATACENTER",
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
					:insecure => get_config(:vsphere_insecure)
				}

				#    opt :debug, "Log SOAP messages", :short => 'd', :default => (ENV['RBVMOMI_DEBUG'] || false)

				vim = RbVmomi::VIM.connect conn_opts
				config[:vim] = vim
				return vim
			end

			def find_folder(folderName)
				dcname = get_config(:vsphere_dc)
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
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
				dcname = get_config(:vsphere_dc)
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.network
				baseEntity.find { |f| f.name == networkName } or abort "no such network #{networkName}"
			end

			def find_pool(poolName)
				dcname = get_config(:vsphere_dc)
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.hostFolder
				entityArray = poolName.split('/')
				entityArray.each do |entityArrItem|
					if entityArrItem != ''
						if baseEntity.is_a? RbVmomi::VIM::Folder
							baseEntity = baseEntity.childEntity.find { |f| f.name == entityArrItem } or
                abort "no such pool #{poolName} while looking for #{entityArrItem}"
						elsif baseEntity.is_a? RbVmomi::VIM::ClusterComputeResource
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

			def find_datastore(dsName)
				dcname = get_config(:vsphere_dc)
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.datastore
				baseEntity.find { |f| f.info.name == dsName } or abort "no such datastore #{dsName}"
			end


			def find_all_in_folder(folder, type)
				if folder.instance_of?(RbVmomi::VIM::ClusterComputeResource)
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

		end
	end
end
