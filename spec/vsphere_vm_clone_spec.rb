require 'spec_helper'
require 'chef/knife/vsphere_vm_clone'

describe Chef::Knife::VsphereVmClone do
  let(:datacenter) { double('Datacenter', vmFolder: empty_folder, hostFolder: empty_folder) }
  let(:vim) { double('VimConnection', serviceContent: service_content) }
  let(:service_content) { double('ServiceContent') }
  let(:root_folder) { double('RootFolder', children: []) }
  let(:empty_folder) { double('Folder', childEntity: [], children: []) }
  let(:host) { double('Host', resourcePool: double('ResourcePool')) }
  let(:task) { double('Task', wait_for_completion: 'done') }

  subject { described_class.new }

  before do
    subject.config[:random_vmname_prefix] = 'vm-'
    subject.config[:vsphere_pass] = 'password'
    subject.config[:vsphere_host] = 'host'
    subject.config[:verbosity] = 0
    subject.config[:customization_ips] = Chef::Knife::VsphereVmClone::NO_IPS
    subject.config[:customization_macs] = Chef::Knife::VsphereVmClone::AUTO_MAC
  end

  context 'input handling' do
    before do
      subject.config[:source_vm] = 'my_template'
    end

    it 'requires a vm name' do
      expect { subject.run }.to raise_error SystemExit
    end

    it 'takes a hostname' do
      subject.name_args = 'foo'
      expect(subject).to receive(:vim_connection).and_raise ArgumentError
      expect { subject.run }.to raise_error ArgumentError
    end
  end

  context 'customizing the mac' do
    let(:template) { double('Template', config: {}) }

    before do
      allow(subject).to receive(:vim_connection).and_return(vim)
      # It is difficult to mock this because the current implementation checks
      # for explicity RbVmomi class names
      allow(subject).to receive(:datacenter).and_return(datacenter)
      allow(subject).to receive(:find_available_hosts).and_return( [host])

      allow(service_content).to receive(:virtualDiskManager) # what does this call actually do?
      subject.config[:folder] = ''
      subject.config[:source_vm] = 'my_template'
    end

    context 'the mac is given' do
      it 'requires an ip' do
        subject.name_args = 'foo'
        subject.config[:customization_macs] = '00:11:22:33:44:55'

        expect { subject.run }.to raise_error SystemExit
      end
    end

    context 'the mac is not given' do
      before do
        subject.name_args = 'foo'

        allow(subject).to receive(:find_in_folder).and_return(template)
      end

      it 'runs without specifying an ip' do
        expect(template).to receive(:CloneVM_Task).and_return(task)
        expect { subject.run }.to_not raise_error
      end

      it 'runs while specifying an ip' do
        subject.config[:customization_ips] = '1.2.3.4'

        expect(template).to receive(:CloneVM_Task).and_return(task)
        expect { subject.run }.to_not raise_error
      end
    end
  end

  context 'customizations' do
    context 'skip customizations'
    context 'determining the hostname'
    context 'windows clone'
    context 'linux clone'
    context 'neither windows or linux'
  end
end
