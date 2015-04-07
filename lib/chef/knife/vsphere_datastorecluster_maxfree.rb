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

def max_dscluster(dscluster, max_dscluster)
  return true unless max_dscluster

  if dscluster.summary[:freeSpace] > max_dscluster.summary[:freeSpace]
    return true
  end

  false
end

def find_max_dscluster(folder, max_dscluster, regex)
  folder.childEntity.each do |child|
    if child.class.to_s == 'Folder'
      sub_max = find_max_dscluster(child, max_dscluster, regex)
      max_dscluster = sub_max if max_dscluster(sub_max, max_dscluster)
    elsif child.class.to_s == 'StoragePod'
      if max_dscluster(child, max_dscluster) && regex.match(child.name)
        max_dscluster = child
      end
    end
  end

  max_dscluster
end

# Gets the data store cluster with the most free space in datacenter
class Chef::Knife::VsphereDatastoreclusterMaxfree < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere datastorecluster maxfree'

  option :regex,
         short: '-r REGEX',
         long: '--regex REGEX',
         description: 'Regex to match the datastore cluster name',
         default: ''
  common_options

  def run
    $stdout.sync = true

    regex = /#{Regexp.escape(get_config(:regex))}/
    max_dscluster = nil

    vim_connection
    dc = datacenter

    max_dscluster = find_max_dscluster(dc.datastoreFolder, max_dscluster, regex)

    if max_dscluster
      puts max_dscluster.name
    else
      puts 'No datastore clusters found'
      exit 1
    end
  end
end
