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
  storage_units_fmt = ["byte", "kB", "MB", "GB", "TB"]
  base = 1024
  if number.to_i < base
    unit = storage_units_fmt[0]
  else
    max_exp = storage_units_fmt.size - 1
    exponent = (Math.log(number) / Math.log(base)).to_i # Convert to base
    exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit
    number /= base ** exponent
    unit = storage_units_fmt[exponent]
  end

  return sprintf("%0.2f %s", number, unit)
end


# Lists all known data store cluster in datacenter with sizes
class Chef::Knife::VsphereDatastoreclusterList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere datastore list"

  get_common_options

  def run
    $stdout.sync = true

    vim = get_vim_connection
    dc = get_datacenter
    dc.datastoreFolder.childEntity.each do |store|
	  if store.class.to_s == "StoragePod"
		avail = number_to_human_size(store.summary[:freeSpace])
		cap = number_to_human_size(store.summary[:capacity])
		puts "#{ui.color("DatastoreCluster", :cyan)}: #{store.name} (#{avail} / #{cap})"
	  end
    end
  end
end

