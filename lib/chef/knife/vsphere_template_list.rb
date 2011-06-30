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

class Chef
  class Knife
    class VsphereTemplateList < VsphereBaseCommand

      banner "knife vsphere template list"

      get_common_options
      

      def run

        $stdout.sync = true
        
        vim = get_vim_connection

        dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
        dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
                       
        vmFolders = get_folders(dc.vmFolder)

        vms = find_all_in_folders(dc.vmFolder, RbVmomi::VIM::VirtualMachine).
          select {|v| !v.config.nil? && v.config.template == true }
      
        vms.each do |vm|          
          puts "#{ui.color("Template Name", :cyan)}: #{vm.name}"
        end
      end
    end
  end
end
