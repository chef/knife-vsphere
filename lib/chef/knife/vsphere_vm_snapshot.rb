#
# License:: Apache License, Version 2.0
#

require "chef/knife"
require "chef/knife/base_vsphere_command"
require "chef/knife/search_helper"

# Manage snapshots of a virtual machine
class Chef::Knife::VsphereVmSnapshot < Chef::Knife::BaseVsphereCommand
  include SearchHelper
  banner "knife vsphere vm snapshot VMNAME (options)"

  common_options

  option :list,
    long: "--list",
    description: "The current tree of snapshots"

  option :create_new_snapshot,
    long: "--create SNAPSHOT",
    description: "Create a new snapshot off of the current snapshot."

  option :remove_named_snapshot,
    long: "--remove SNAPSHOT",
    description: "Remove a named snapshot."

  option :revert_snapshot,
    long: "--revert SNAPSHOT",
    description: "Revert to a named snapshot."

  option :revert_current_snapshot,
    long: "--revert-current",
    description: "Revert to current snapshot.",
    boolean: false

  option :power,
    long: "--start",
    description: "Indicates whether to start the VM after a successful revert",
    boolean: false

  option :wait,
    long: "--wait",
    description: "Indicates whether to wait for creation/removal to complete",
    boolean: false

  option :find, # imma deprecate this
    long: "--find",
    description: "Finds the virtual machine by searching all folders"

  option :dump_memory,
    long: "--dump-memory",
    boolean: true,
    description: "Dump the memory in the snapshot",
    default: false

  option :quiesce,
    long: "--quiesce",
    boolean: true,
    description: "Quiesce the VM prior to snapshotting",
    default: false

  option :snapshot_description,
    long: "--snapshot-descr DESCR",
    description: "Snapshot description",
    default: ""

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal("You must specify a virtual machine name")
      exit 1
    end

    vm = get_vm_by_name(vmname, get_config(:folder)) || fatal_exit("Could not find #{vmname}")

    if vm.snapshot
      snapshot_list = vm.snapshot.rootSnapshotList
      current_snapshot = vm.snapshot.currentSnapshot
    end

    if get_config(:list) && vm.snapshot
      ui.output(snapshot_list.map { |i| display_node(i, current_snapshot) })
    end

    if get_config(:create_new_snapshot)
      snapshot_task = vm.CreateSnapshot_Task(name: get_config(:create_new_snapshot),
                                             description: get_config(:snapshot_description),
                                             memory: get_config(:dump_memory),
                                             quiesce: get_config(:quiesce))
      snapshot_task = snapshot_task.wait_for_completion if get_config(:wait)
      snapshot_task
    end

    if get_config(:remove_named_snapshot)
      ss_name = get_config(:remove_named_snapshot)
      snapshot = find_node(snapshot_list, ss_name)
      puts "Found snapshot #{ss_name} removing."
      snapshot_task = snapshot.RemoveSnapshot_Task(removeChildren: false)
      snapshot_task = snapshot_task.wait_for_completion if get_config(:wait)
      snapshot_task
    end

    if get_config(:revert_current_snapshot)
      puts "Reverting to Current Snapshot"
      vm.RevertToCurrentSnapshot_Task(suppressPowerOn: false).wait_for_completion
      if get_config(:power)
        vm.PowerOnVM_Task.wait_for_completion
        puts "Powered on virtual machine #{vmname}"
      end
    end

    return unless get_config(:revert_snapshot)

    ss_name = get_config(:revert_snapshot)
    snapshot = find_node(snapshot_list, ss_name)
    snapshot.RevertToSnapshot_Task(suppressPowerOn: false).wait_for_completion
    return unless get_config(:power)

    vm.PowerOnVM_Task.wait_for_completion
    puts "Powered on virtual machine #{vmname}"
  end

  def find_node(tree, name)
    snapshot = nil
    tree.each do |node|
      if node.name == name
        snapshot = node.snapshot
        break
      elsif !node.childSnapshotList.empty?
        snapshot = find_node(node.childSnapshotList, name)
      end
    end
    snapshot
  end

  def display_node(node, current)
    children = node.childSnapshotList.map { |item| display_node(item, current) }
    snapshot_tree = { "SnapshotName" => node.name,
                      "SnapshotId" => node.id,
                      "SnapshotDescription" => node.description,
                      "SnapshotCreationDate" => node.createTime.iso8601,
                      "Children" => children }
    snapshot_tree["IsCurrentSnapshot"] = true if node.snapshot == current
    snapshot_tree
  end
end
