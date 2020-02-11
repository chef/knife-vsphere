require "spec_helper"
require "chef/knife/vsphere_vm_snapshot"

describe Chef::Knife::VsphereVmSnapshot do
  let(:datacenter) { double("Datacenter") }
  let(:vim) { double("VimConnection", serviceContent: service_content) }
  let(:service_content) { double("ServiceContent") }

  subject { described_class.new }

  before do
    described_class.load_deps
    subject.config[:vsphere_pass] = "password"
    subject.config[:vsphere_host] = "host"
  end

  context "input handling" do
    it "requires a vm name" do
      expect { subject.run }.to raise_error SystemExit
    end

    it "takes a hostname" do
      subject.name_args = "foo"
      expect(subject).to receive(:vim_connection).and_raise ArgumentError
      expect { subject.run }.to raise_error ArgumentError
    end
  end
end
