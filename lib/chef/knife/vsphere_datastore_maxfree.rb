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

require "chef/knife"
require "chef/knife/base_vsphere_command"

# Gets the data store with the most free space in datacenter
# VsphereDatastoreMaxfree extends the BaseVspherecommand
class Chef::Knife::VsphereDatastoreMaxfree < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere datastore maxfree"

  option :regex,
    short: "-r REGEX",
    long: "--regex REGEX",
    description: "Regex to match the datastore name",
    default: ""

  option :vlan,
    long: "--vlan VLAN",
    description: "Require listed vlan available to datastore's parent"

  option :pool,
    long: "--pool pool",
    description: "Pool or Cluster to search for datastores in"

  common_options

  # The main run method for datastore_maxfree
  #
  def run
    $stdout.sync = true
    if get_config(:vlan) && get_config(:pool)
      fatal_exit("Please select either vlan or pool")
    end

    vim_connection
    regex = /#{get_config(:regex)}/
    max = nil
    datastores = find_datastores
    datastores.each do |store|
      if regex.match(store.name) &&
          (max.nil? || max.summary[:freeSpace] < store.summary[:freeSpace])
        max = store
      end
    end
    ui.output(max ? { "Datastore" => max.name } : {})
  end
end

private

def find_datastores
  if get_config(:vlan)
    find_network(get_config(:vlan)).host.map(&:datastore).flatten
  elsif get_config(:pool)
    find_pools_and_clusters(datacenter.hostFolder, get_config(:pool)).map(&:datastore).flatten
  else
    datacenter.datastore
  end
end
