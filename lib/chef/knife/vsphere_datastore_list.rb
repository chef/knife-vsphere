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

# Lists all known data stores in datacenter with sizes
class Chef::Knife::VsphereDatastoreList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere datastore list'

  common_options

  option :list,
         long: '--list',
         short: '-L',
         description: "Indicates whether to list VM's in datastore",
         boolean: true

  def run
    $stdout.sync = true

    vim_connection
    dc = datacenter
    dc.datastore.each do |store|
      avail = number_to_human_size(store.summary[:freeSpace])
      cap = number_to_human_size(store.summary[:capacity])
      puts "#{ui.color('Datastore', :cyan)}: #{store.name} (#{avail} / #{cap})"
      next unless get_config(:list)
      store.vm.each do |vms|
        host_name = vms.guest[:hostName]
        guest_full_name = vms.guest[:guest_full_name]
        guest_state = vms.guest[:guest_state]
        puts "#{ui.color('VM Name:', :green)} #{host_name} #{ui.color('OS:', :magenta)} #{guest_full_name} #{ui.color('State:', :cyan)} #{guest_state}"
      end
    end
  end
end
