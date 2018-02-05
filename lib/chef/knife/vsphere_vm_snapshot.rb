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

  option :wait,
         long: '--wait',
         description: 'Indicates whether to wait for creation/removal to complete',
         boolean: false

  option :find,
         long: '--find',
         description: 'Finds the virtual machine by searching all folders'

  option :dump_memory,
         long: '--dump-memory',
         boolean: true,
         description: 'Dump the memory in the snapshot',
         default: false

  option :quiesce,
         long: '--quiesce',
         boolean: true,
         description: 'Quiesce the VM prior to snapshotting',
         default: false

  option :snapshot_description,
         long: '--snapshot-descr DESCR',
         description: 'Snapshot description',
         default: ' '

  def run
    $stdout.sync = true

    vmname = @name_args[0]
    if vmname.nil?
      show_usage
      ui.fatal('You must specify a virtual machine name')
      exit 1
    end

    vim_connection

    vm = if get_config(:find)
           puts "No folder entered, searching for #{vmname}"
           src_folder = find_folder(get_config(:folder))
           traverse_folders_for_vm(src_folder, vmname)
         else
           base_folder = find_folder get_config(:folder)
           find_in_folder(base_folder, RbVmomi::VIM::VirtualMachine, vmname) || abort("VM #{vmname} not found")
         end

    if vm.snapshot
      snapshot_list = vm.snapshot.rootSnapshotList
      current_snapshot = vm.snapshot.currentSnapshot
    end

    if get_config(:list) && vm.snapshot
      puts 'Current snapshot tree: '
      puts "#{vmname}"
      snapshot_list.each { |i| puts display_node(i, current_snapshot) }
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
      puts 'Reverting to Current Snapshot'
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

  def display_node(node, current, shift = 1)
    descr = node.name + ' ' + node.createTime.iso8601
    out = ''
    out << '+--' * shift
    if node.snapshot == current
      out << "#{ui.color(descr.to_s, :cyan)}" << "\n"
    else
      out << "#{descr.to_s}" << "\n"
    end
    unless node.childSnapshotList.empty?
      node.childSnapshotList.each { |item| out << display_node(item, current, shift + 1) }
    end
    out
  end
end
