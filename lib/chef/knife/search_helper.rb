# Some helpers for faster searching of the inventory
module SearchHelper
  # Retrieves all the VM objects and returns their ObjectContents
  # Note that since it's a ObjectContent coming back, the individual
  # object's [] will return only the properties you asked for
  # and `#obj` will return the actual object (but make a call to the server)
  # param [Array<String>] properties to retrieve
  # @return [Array<RbVmomi::VIM::ObjectContent>]
  def get_all_vm_objects(opts = {})
    pc = vim_connection.serviceInstance.content.propertyCollector
    viewmgr = vim_connection.serviceInstance.content.viewManager
    folder = if opts[:folder]
               find_folder(opts[:folder])
             else
               vim_connection.serviceInstance.content.rootFolder
             end
    vmview = viewmgr.CreateContainerView(container: folder,
                                         type: ['VirtualMachine'],
                                         recursive: true)

    opts[:properties] ||= ['name']

    filter_spec = RbVmomi::VIM.PropertyFilterSpec(
      objectSet: [
        obj: vmview,
        skip: true,
        selectSet: [
          RbVmomi::VIM.TraversalSpec(
            name: 'traverseEntities',
            type: 'ContainerView',
            path: 'view',
            skip: false
          )
        ]
      ],
      propSet: [
        { type: 'VirtualMachine', pathSet: opts[:properties] }
      ]
    )
    pc.RetrieveProperties(specSet: [filter_spec])
  end

  def get_vm_by_name(vmname, folder = nil)
    vm = get_all_vm_objects(folder: folder).detect { |r| r['name'] == vmname }
    vm ? vm.obj : nil
  end
end
