#r# Author:: Ezra Pagel (<ezra@cpan.org>)
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

class Chef
  class Knife
    class VsphereVmList < VsphereBaseCommand

      banner "knife vsphere vm list"

      get_common_options
      
      option :folder,
      :short => "-f SHOWFOLDER",
      :long => "--folder",
      :description => "The folder to list VMs in"

      def run

        $stdout.sync = true
        
        vim = get_vim_connection


        dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
        dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
                       
        baseFolder = dc.vmFolder;

        if config[:folder]
          baseFolder = get_folders(dc.vmFolder).find { |f| f.name == config[:folder]} or
            abort "no such folder #{config[:folder]}"
        end

        vms = find_all_in_folders(baseFolder, RbVmomi::VIM::VirtualMachine)      
        vms.each do |vm|          
          puts "#{ui.color("Template Name", :cyan)}: #{vm.name}"
        end
      end
    end
  end
end
