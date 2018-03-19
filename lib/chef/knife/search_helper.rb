# Some helpers for faster searching of the inventory
module SearchHelper
  # Retrieves all the VM objects and returns their ObjectContents
  # Note that since it's a ObjectContent coming back, the individual
  # object's [] will return only the properties you asked for
  # and `#obj` will return the actual object (but make a call to the server)
  # param [Array<String>] properties to retrieve
  # @return [Array<RbVmomi::VIM::ObjectContent>]
  def get_all_vm_objects(properties = ['name'])
    pc = vim_connection.serviceInstance.content.propertyCollector
    viewmgr = vim_connection.serviceInstance.content.viewManager
    root_folder = vim_connection.serviceInstance.content.rootFolder
    vmview = viewmgr.CreateContainerView(container: root_folder,
                                         type: ['VirtualMachine'],
                                         recursive: true)

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
        { type: 'VirtualMachine', pathSet: properties }
      ]
    )
    pc.RetrieveProperties(specSet: [filter_spec])
  end

  def get_vm_by_name(vmname)
    vm = get_all_vm_objects.detect { |r| r['name'] == vmname }
    vm ? vm.obj : nil
  end
end
