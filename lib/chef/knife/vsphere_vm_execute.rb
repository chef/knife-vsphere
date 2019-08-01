# Author:: Ian Delahorne (<ian@delahorne.com>)
# License:: Apache License, Version 2.0

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# VsphereVMexecute extends the Basevspherecommand
class Chef::Knife::VsphereVmExecute < Chef::Knife::BaseVsphereCommand
  include SearchHelper

  banner "knife vsphere vm execute VMNAME COMMAND ARGS"

  option :exec_user,
    long: "--exec-user USER",
    description: "User to execute as",
    required: true

  option :exec_passwd,
    long: "--exec-passwd PASSWORD",
    description: "Password for execute user",
    required: true

  option :exec_dir,
    long: "--exec-dir DIRECTORY",
    description: "Working directory to execute in"

  common_options

  # The main run method for vm_execute
  #
  def run
    $stdout.sync = true
    vmname = @name_args.shift
    if vmname.nil?
      show_usage
      fatal_exit("You must specify a virtual machine name")
    end
    command = @name_args.shift
    if command.nil?
      show_usage
      fatal_exit("You must specify a command to execute")
    end

    args = @name_args
    args = [] if args.nil?

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    gom = vim_connection.serviceContent.guestOperationsManager

    guest_auth = RbVmomi::VIM::NamePasswordAuthentication(interactiveSession: false,
                                                          username: config[:exec_user],
                                                          password: config[:exec_passwd])
    prog_spec = RbVmomi::VIM::GuestProgramSpec(programPath: command,
                                               arguments: args.join(" "),
                                               workingDirectory: get_config(:exec_dir))

    gom.processManager.StartProgramInGuest(vm: vm, auth: guest_auth, spec: prog_spec)
  end
end
