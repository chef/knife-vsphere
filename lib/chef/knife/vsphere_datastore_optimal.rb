# Copyright (C) 2012, SCM Ventures AB
# Author: Ian Delahorne <ian@scmventures.se>
#
# Permission to use, copy, modify, and/or distribute this software for
# any purpose with or without fee is hereby granted, provided that the
# above copyright notice and this permission notice appear in all
# copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
# OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE

require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Gets the data store with the most free space in datacenter
class Chef::Knife::VsphereDatastoreOptimal < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere datastore optimal'

  option :regex,
         short: '-r REGEX',
         long: '--regex REGEX',
         description: 'Regex to match the datastore name',
         default: ''

  option :size,
         long: '--size SIZE',
         description: 'the total size of the VM to create or size to add when cloning a VM'

  option :free,
         short: '-f FREE',
         long: '--free FREE',
         description: 'minimal percent free of the datastore accepted'

  option :vm_name,
         short: '-n NAME',
         long:  '--name NAME',
         description: 'name of the vm',

  common_options

  def run
    $stdout.sync = true

    vim_connection
    dcname = get_config(:vsphere_dc)
    regex = /#{Regexp.escape(get_config(:regex))}/
    dc = config[:vim].serviceInstance.find_datacenter(dcname) || abort('datacenter not found')
    
    vm_size=0
    if get_config(:vm_name)
      src_folder = find_folder(get_config(:folder)) || dc.vmFolder
      vm = find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, get_config(:vm_name)) ||
             abort('VM/Template not found')
      disks = vm.config.hardware.device.grep(RbVmomi::VIM::VirtualDisk)
      disks.each do |disk|
        if disk.capacityInBytes != nil
          vm_size+=disk.capacityInBytes
        end
      end
    end

    if get_config(:size)
      vm_size+=get_config(:size).to_i
    end

    Chef::Log.debug("size for the new VM = #{vm_size}")

    store=nil
    store_usedafter=0
    regex = /#{Regexp.escape(get_config(:regex))}/
    datastores = dc.datastore
    datastores.each do |datastore|
      if datastore.summary[:type] == "VMFS" && regex.match(datastore.name)
        freespace = datastore.summary[:freeSpace].to_f
        capacity = datastore.summary[:capacity].to_f

        used = capacity - freespace
        pused = (used*100/capacity).to_i
        pused_after = (((used+vm_size)*100)/capacity).to_i

        Chef::Log.debug("#{datastore.name}   #{datastore.summary[:freeSpace].to_s}/#{datastore.summary[:capacity].to_s}    #{pused.to_s}/#{pused_after.to_s}")


        if (store.nil? && (100-pused_after>=options[:free]))  || (100-pused_after>=options[:free] && pused_after>store_usedafter)
          store = datastore
          store_usedafter = pused_after
        end
      end
    end
    puts store ? store.name : 'ERROR'
  end
end
