require 'spec_helper'
require 'chef/knife/vsphere_vm_vmdk_add'

describe Chef::Knife::VsphereVmVmdkAdd do
  let(:datacenter) { double('Datacenter') }
  let(:vim) { double('VimConnection', serviceContent: service_content) }
  let(:service_content) { double('ServiceContent', virtualDiskManager: 'vdm') }

  subject { described_class.new }

  before do
    subject.config[:random_vmname_prefix] = 'vm-'
    subject.config[:vsphere_pass] = 'password'
    subject.config[:vsphere_host] = 'host'
  end

  context 'input handling' do
    it 'requires a vm name' do
      expect { subject.run }.to raise_error SystemExit
    end

    it 'requires a vmdk size' do
      subject.name_args = ['foo']
      expect { subject.run }.to raise_error SystemExit
    end

    it 'requires a vm name and a vmdk size' do
      subject.name_args = ['foo', 42]

      expect(subject).to receive(:vim_connection).and_raise ArgumentError
      expect { subject.run }.to raise_error ArgumentError
    end
  end

  context 'finding a vm' do
    it 'exits if the vm is not found' do
      subject.name_args = ['foo', 42]
      expect(subject).to receive(:vim_connection).and_return(vim)

      expect(subject).to receive(:get_vm).with('foo').and_return(false)

      expect { subject.run }.to raise_error SystemExit
    end

  end
end
