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
class Chef::Knife::VsphereDatastoreMaxfree < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere datastore maxfree'

  option :regex,
         short: '-r REGEX',
         long: '--regex REGEX',
         description: 'Regex to match the datastore name',
         default: ''

  common_options

  def run
    $stdout.sync = true

    vim_connection
    dcname = get_config(:vsphere_dc)
    regex = /#{Regexp.escape(get_config(:regex))}/
    dc = config[:vim].serviceInstance.find_datacenter(dcname) || abort('datacenter not found')
    max = nil
    dc.datastore.each do |store|
      if regex.match(store.name) && (max.nil? || max.summary[:freeSpace] < store.summary[:freeSpace])
        max = store
      end
    end
    puts max ? max.name : ''
  end
end
