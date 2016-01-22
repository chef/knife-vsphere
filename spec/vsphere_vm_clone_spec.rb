require 'spec_helper'
require 'chef/knife/vsphere_vm_clone'

describe Chef::Knife::VsphereVmClone do
  let(:datacenter) { double('Datacenter') }
  let(:vim) { double('VimConnection', serviceContent: service_content) }
  let(:service_content) { double('ServiceContent') }

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

    it 'takes a hostname' do
      subject.name_args = 'foo'
      expect(subject).to receive(:vim_connection).and_raise ArgumentError
      expect { subject.run }.to raise_error ArgumentError
    end

    it 'tests hound' do
      expect(1).to eq(1)
    end
  end
end
