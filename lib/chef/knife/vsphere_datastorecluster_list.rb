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

def traverse_folders_for_dsclusters(folder)
  print_dsclusters_in_folder(folder)
  folder.childEntity.each do |child|
    traverse_folders_for_dsclusters(child) if child.class.to_s == 'Folder'
  end
end

def print_dsclusters_in_folder(folder)
  folder.childEntity.each do |child|
    next unless child.class.to_s == 'StoragePod'
    avail = number_to_human_size(child.summary[:freeSpace])
    cap = number_to_human_size(child.summary[:capacity])
    puts "#{ui.color('DatastoreCluster', :cyan)}: #{child.name} (#{avail} / #{cap})"
  end
end

# Lists all known data store cluster in datacenter with sizes
class Chef::Knife::VsphereDatastoreclusterList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere datastorecluster list'

  common_options

  def run
    $stdout.sync = true
    vim_connection
    dc = datacenter
    traverse_folders_for_dsclusters(dc.datastoreFolder)
  end
end
