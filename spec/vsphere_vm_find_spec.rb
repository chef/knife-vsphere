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

  context 'asking for the deprecated ips and networks' do
    before do
      subject.config[:ips] = true
    end

    it 'tells the user to use --networks' do
      expect(subject).to receive(:abort).and_raise(SystemExit)
      expect { subject.run }.to raise_error(SystemExit)
    end
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
      expect(subject).to receive(:ui).and_return(ui)
      allow(subject).to receive(:traverse_folders_for_pool_clustercompute).and_return(compute_resource)
    end

    it 'returns the one vm' do
      expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms'}])

      subject.run
    end

    context 'asking for a hostname' do
      before do
        subject.config[:hostname] = true
        allow(guest).to receive(:hostName).and_return('thehost.example.com')
      end

      it 'includes the hostname in the output' do
        expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms', 'hostname'=>'thehost.example.com'}])

        subject.run
      end
    end

    context 'asking for the name of the guests host' do
      before do
        subject.config[:host_name] = true
        allow(vm1).to receive_message_chain(:summary, :runtime, :host, :name) { 'host1' }
      end
      it 'includes the host_name in the output' do
        expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms', 'host_name'=>'host1'}])

        subject.run
      end
    end

    context 'asking for the primary ip' do
      let(:ip) { '1.2.3.4' }

      before do
        subject.config[:ip] = true
        allow(guest).to receive(:ipAddress).and_return(ip)
      end

      it 'returns the ip' do
        expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms', 'ip'=>ip}])
        subject.run
      end
    end

    context 'asking for the networks' do
      before do
        subject.config[:networks] = true
        expect(guest).to receive(:net).and_return(networks)
      end

      context 'a single network' do
        let(:net1) { double('Network', network: 'VLAN1', ipConfig: ipconfig1) }
        let(:ipconfig1) { double('IPconfig', ipAddress: [ip1] ) }
        let(:ip1) { double('IPAddress', ipAddress: '1.2.3.4', prefixLength: '24')}
        let(:networks) { [ net1 ] }

        before do
          allow(vm1).to receive_message_chain(:summary, :runtime, :host, :name) { 'host1' }
        end

        it 'returns the network and IP' do
          expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms', 'networks' => [ { 'name' => 'VLAN1', 'ip' => '1.2.3.4', 'prefix' => '24'}] }])
          subject.run
        end
      end

      context 'multiple networks' do
      end
    end

    context 'asking for the full path' do
      let(:parent1) { double('Parent', name: 'vms', parent: nil) }
      let(:parent2) { double('Parent', name: 'projectX', parent: parent1) }

      before do
        subject.config[:full_path] = true
      end

      context 'with one path element' do
        before do
          allow(vm1).to receive(:parent).and_return(parent1)
        end

        it 'returns the name of the folder' do
          expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms'}])
          subject.run
        end
      end

      context 'with a nested folder' do
        before do
          allow(vm1).to receive(:parent).and_return(parent2)
        end

        it 'returns the name of the folder' do
          expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms/projectX'}])
          subject.run
        end
      end
    end

    context 'asking for the os disks' do
      let(:disk1) { double('Disk', capacity: 10000 * 1024 * 1024, diskPath: 'disk1', freeSpace: 500 * 1024 * 1024)}
      before do
        subject.config[:os_disk] = true
        allow(guest).to receive(:disk).and_return([disk1])
      end

      it 'returns the disks' do
        expect(ui).to receive(:output).with([{'state'=>'on', 'name'=>'myvm', 'folder'=>'vms', 'disks' => [ { 'name' =>'disk1', 'capacity' => 10000, 'free' => 500 } ]}])
        subject.run
      end
    end
  end
end
