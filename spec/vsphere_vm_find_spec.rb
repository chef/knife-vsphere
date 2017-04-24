require 'spec_helper'
require 'chef/knife/vsphere_vm_find'

describe Chef::Knife::VsphereVmFind do
  subject { described_class.new }

  let(:compute_resource) { double('ClusterComputeResource', resourcePool: the_pool) }
  let(:the_pool) { double('VmList', vm: vmlist) }
  let(:ui) { double('ChefUI') }

  before do
    subject.config[:pool] = 'testpool'
    subject.config[:matchname] = 'myvm'
  end

  context 'simply looking for a vm' do
    include_context 'basic_setup'

    let(:runtime) { double('RunTime', powerState: 'poweredOn') }
    let(:parent) { double('ManagedEntity', name: 'vms') }
    let(:guest) { double('Guest', guestFullName: 'Windows 2000 Professional') }
    let(:vm1) { double('VM', runtime: runtime, name: 'myvm', guest: guest, parent: parent) }
    let(:vm2) { double('VM', name: 'anothervm') }

    let(:vmlist) { [ vm1, vm2 ] }

    before do
      allow(subject).to receive(:traverse_folders_for_pool_clustercompute).and_return(compute_resource)
    end

    it 'returns the one vm' do
      expect(subject).to receive(:ui).and_return(ui)
      expect(ui).to receive(:output).with([{"state"=>"on", "name"=>"myvm", "folder"=>"vms"}])

      subject.run
    end
  end
end
