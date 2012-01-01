#
# Author:: Ezra Pagel (<ezra@cpan.org>)
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

				option :vsphere_user,
					:short => "-u USERNAME",
					:long => "--user USERNAME",
					:description => "The username for the host"

				option :password,
					:short => "-p PASSWORD",
					:long => "--password PASSWORD",
					:description => "The password for the host"

				option :datacenter,
					:short => "-d DATACENTER",
					:long => "--datacenter DATACENTER",
					:description => "The Datacenter to create the VM in"

				option :path,
					:long => "--path SOAP_PATH",
					:description => "The SOAP endpoint path",
					:proc => Proc.new { |p| Chef::Config[:knife][:path] = p },
					:default => "/sdk"

				option :port,
					:long => "--port PORT",
					:description => "The VI SDK port number to use",
					:proc => Proc.new { |p| Chef::Config[:knife][:port] = p },
					:default => 443

				option :use_ssl,
					:long => "--ssl USE_SSL",
					:description => "Whether to use SSL connection",
					:default => true

				option :insecure,
					:short => "-i USE_INSECURE_SSL",
					:long => "--insecure USE_INSECURE_SSL",
					:description => "Determines whether SSL certificate verification is skipped",
					:default => true

				option :folder,
					:short => "-f FOLDER",
					:long => "--folder FOLDER",
					:description => "The folder to get VMs from",
					:default => ''

			end

			def get_vim_connection

				conn_opts = {
					:host => config[:host] || Chef::Config[:knife][:vsphere_host],
					:path => config[:path],
					:port => config[:port],
					:use_ssl => config[:ssl],
					:user => config[:vsphere_user] || Chef::Config[:knife][:vsphere_user],
					:password => config[:password] || Chef::Config[:knife][:vsphere_pass],
					:insecure => config[:insecure]
				}

				#    opt :insecure, "don't verify ssl certificate", :short => 'k', :default => (ENV['RBVMOMI_INSECURE'] == '1')
				#    opt :debug, "Log SOAP messages", :short => 'd', :default => (ENV['RBVMOMI_DEBUG'] || false)

				vim = RbVmomi::VIM.connect conn_opts
				config[:vim] = vim
				return vim
			end

			def find_folder(folderName)
				dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.vmFolder
				entityArray = folderName.split('/')
				entityArray.each do |entityArrItem|
					if entityArrItem != ''
						baseEntity = baseEntity.childEntity.grep(RbVmomi::VIM::Folder).find { |f| f.name == entityArrItem } or abort "no such folder #{folderName} while looking for #{entityArrItem}"
					end
				end
				baseEntity
			end

			def find_pool(poolName)
				dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.hostFolder
				entityArray = poolName.split('/')
				entityArray.each do |entityArrItem|
					if entityArrItem != ''
						baseEntity = baseEntity.resourcePool.find { |f| f.name == entityArrItem } or abort "no such pool #{poolName} while looking for #{entityArrItem}"
					end
				end
				baseEntity
			end

			def find_datastore(dsName)
				dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
				dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
				baseEntity = dc.datastore
				baseEntity.find { |f| f.info.name == dsName } or abort "no such datastore #{dsName}"
			end


			def find_all_in_folder(folder, type)
				folder.childEntity.grep(type)
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
