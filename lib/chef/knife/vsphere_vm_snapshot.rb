#
# License:: Apache License, Version 2.0
#

require 'chef/knife'
require 'chef/knife/base_vsphere_command'
require 'rbvmomi'
require 'netaddr'

# Manage snapshots of a virtual machine
class Chef::Knife::VsphereVmSnapshot < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm snapshot VMNAME (options)'

  common_options

  option :list,
         long: '--list',
         description: 'The current tree of snapshots'

  option :create_new_snapshot,
         long: '--create SNAPSHOT',
         description: 'Create a new snapshot off of the current snapshot.'

  option :remove_named_snapshot,
         long: '--remove SNAPSHOT',
         description: 'Remove a named snapshot.'

  option :revert_snapshot,
         long: '--revert SNAPSHOT',
         description: 'Revert to a named snapshot.'

  option :revert_current_snapshot,
         long: '--revert-current',
         description: 'Revert to current snapshot.',
         boolean: false

  option :power,
         long: '--start',
         description: 'Indicates whether to start the VM after a successful revert',
         boolean: false

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal('You must specify a virtual machine name')
      exit 1
    end

    vim_connection

    base_folder = find_folder(get_config(:folder))

    vm = find_in_folder(base_folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")

    if vm.snapshot
      snapshot_list = vm.snapshot.rootSnapshotList
      current_snapshot = vm.snapshot.currentSnapshot
    end

    if config[:list] && vm.snapshot
      puts 'Current snapshot tree: '
      puts "#{vmname}"
      snapshot_list.each { |i| puts display_node(i, current_snapshot) }
    end

    if config[:create_new_snapshot]
      vm.CreateSnapshot_Task(name: config[:create_new_snapshot], description: '', memory: false, quiesce: false)
    end

    if config[:remove_named_snapshot]
      ss_name = config[:remove_named_snapshot]
      snapshot = find_node(snapshot_list, ss_name)
      puts "Found snapshot #{ss_name} removing."
      snapshot.RemoveSnapshot_Task(removeChildren: false)
    end

    if config[:revert_current_snapshot]
      puts 'Reverting to Current Snapshot'
      vm.RevertToCurrentSnapshot_Task(suppressPowerOn: false).wait_for_completion
      if get_config(:power)
        vm.PowerOnVM_Task.wait_for_completion
        puts "Powered on virtual machine #{vmname}"
      end
    end

    return unless config[:revert_snapshot]
    ss_name = config[:revert_snapshot]
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

  def display_node(node, current, shift = 1)
    out = ''
    out << '+--' * shift
    if node.snapshot == current
      out << "#{ui.color(node.name, :cyan)}" << "\n"
    else
      out << "#{node.name}" << "\n"
    end
    unless node.childSnapshotList.empty?
      node.childSnapshotList.each { |item| out << display_node(item, current, shift + 1) }
    end
    out
  end
end
