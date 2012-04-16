# Author: Jesse Campbell
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
require 'chef/knife/BaseVsphereCommand'

# Lists all known data stores in datacenter with sizes
class Chef::Knife::VsphereVlanList < Chef::Knife::BaseVsphereCommand

  banner "knife vsphere vlan list"

  get_common_options
  def run
    $stdout.sync = true
    
    vim = get_vim_connection
		dcname = get_config(:vsphere_dc)
    dc = config[:vim].serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
    dc.network.each do |network|
      puts "#{ui.color("VLAN", :cyan)}: #{network.name}"
    end
  end
end

