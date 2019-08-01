#
# Author:: Scott Williams (<scott@backups.net.au>)
# License:: Apache License, Version 2.0
#
require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Main class VsphereVMvncset extends the BaseVspherecommand
class Chef::Knife::VsphereVmVncset < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm vncset VMNAME"

  option :vnc_port,
    long: "--vnc-port PORT",
    description: "Port to run VNC on",
    required: true

  option :vnc_password,
    long: "--vnc-password PASSWORD",
    description: "Password for connecting to VNC",
    required: true

  common_options

  # The main run method for vm_vnc_set
  #
  def run
    $stdout.sync = true
    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    extra_config, = vm.collect("config.extraConfig")

    vm.ReconfigVM_Task(
      spec: {
        extraConfig: [
          { key: "RemoteDisplay.vnc.enabled", value: "true" },
          { key: "RemoteDisplay.vnc.port", value: config[:vnc_port].to_s },
          { key: "RemoteDisplay.vnc.password", value: config[:vnc_password].to_s },
        ],
      }
    ).wait_for_completion

    puts extra_config.detect { |x| "RemoteDisplay.vnc.enabled".casecmp(x.key) && "true".casecmp(x.value.downcase) }
  end
end
