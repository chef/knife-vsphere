#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
require 'chef/knife'
require 'chef/knife/base_vsphere_command'

# Lists all known virtual machines in the configured datacenter
class Chef::Knife::VsphereVmList < Chef::Knife::BaseVsphereCommand
  banner 'knife vsphere vm list'

  common_options

  option :recursive,
         long: '--recursive',
         short: '-r',
         description: 'Recurse into sub-folders'

  def traverse_folders(folder, is_top = false, recurse = false)
    vms = find_all_in_folder(folder, RbVmomi::VIM::VirtualMachine).select { |v| v.config && !v.config.template }
    if vms.any?
      puts "#{ui.color('Folder', :cyan)}: " + (folder.path[3..-1].map { |x| x[1] }.* '/')
      vms.each { |v|  print_vm(v) }
    elsif is_top
      puts "#{ui.color('No VMs', :cyan)}"
    end

    return unless recurse
    folders = find_all_in_folder(folder, RbVmomi::VIM::Folder)
    folders.each do |child|
      traverse_folders(child, false, recurse)
    end
  end

  def print_vm(vm)
    state = case vm.runtime.powerState
            when PS_ON
              ui.color('on', :green)
            when PS_OFF
              ui.color('off', :red)
            when PS_SUSPENDED
              ui.color('suspended', :yellow)
            end
    puts "\t#{ui.color('VM Name:', :cyan)} #{vm.name}"
    puts "\t\t#{ui.color('IP:', :magenta)} #{vm.guest.ipAddress}"
    puts "\t\t#{ui.color('RAM:', :magenta)} #{vm.summary.config.memorySizeMB}"
    puts "\t\t#{ui.color('State:', :magenta)} #{state}"
  end

  def run
    vim_connection
    base_folder = find_folder(get_config(:folder))
    recurse =  get_config(:recursive)
    is_top = true
    traverse_folders(base_folder, is_top, recurse)
  end
end
