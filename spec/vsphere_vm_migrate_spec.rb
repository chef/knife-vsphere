require "spec_helper"
require "chef/knife/vsphere_vm_migrate"

describe Chef::Knife::VsphereVmMigrate do
  include_context "stub_vm_search"
  let(:vm) { double("VM") }
  let(:host) { double("Host") }
  let(:task) { double("Task", wait_for_completion: true) }

  subject { described_class.new }

  context "input handling" do
    it "requires a vm name" do
      expect { subject.run }.to raise_error SystemExit
    end

    context "destinations" do
      before do
        subject.name_args = ["foo"]
      end

      it "fails without a destination" do
        expect { subject.run }.to raise_error SystemExit
      end
    end
  end

  context "moving to a new host" do
    before do
      subject.name_args = ["foo"]
      subject.config[:dest_host] = "dest_host"
      allow(subject).to receive(:get_vm_host_by_name).with("dest_host").and_return(host)
    end

    it "sends the spec" do
      expect(vm).to receive(:RelocateVM_Task) do |args|
        expect(args[:spec][:pool]).to be_nil
        expect(args[:spec][:host]).to eq(host)
      end.and_return(task)

      subject.run
    end
  end
end
