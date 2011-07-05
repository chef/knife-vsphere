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
require 'rbvmomi'

class Chef
  class Knife
    class VsphereBaseCommand < Knife

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

      option :host,
      :short => "-H HOST",
      :long => "--host HOST",
      :description => "The host to create the VM on"
      
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
        return vim
      end

      def get_folders(folder)
        folder.childEntity.grep(RbVmomi::VIM::Folder) << folder
      end

      def find_all_in_folders(folder, type)
        get_folders(folder).
          collect { |f| f.childEntity.grep(type) }.
          flatten
      end

      def find_in_folders(folder, type, name)
        get_folders(folder).
          collect { |f| f.childEntity.grep(type) }.
          flatten.
          find { |o| o.name == name }
      end

     

    end
  end
end
