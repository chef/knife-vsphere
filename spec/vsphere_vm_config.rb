require "spec_helper"
require "chef/knife/vsphere_vm_config"

describe Chef::Knife::VsphereVmConfig do
  include_context "stub_vm_search"

  let(:vm) { double("VM") }
  let(:task) { double("Task", wait_for_completion: "") }

  context "input sanity" do
    it "errors if nothing is given" do
      expect { subject.run }.to raise_error SystemExit
    end

    it "errors if only a vm is given" do
      subject.name_args = ["foo"]
      expect { subject.run }.to raise_error SystemExit
    end

    it "errors if a vm and only one param is given" do
      subject.name_args = %w{foo bar}
      expect { subject.run }.to raise_error SystemExit
    end

    it "errors if a vm and an odd number of params are given" do
      subject.name_args = %w{foo bar baz bing}
      expect { subject.run }.to raise_error SystemExit
    end
  end

  context "correct input" do
    before do
      subject.name_args = ["foo"]
    end

    it "sends one pair to vsphere" do
      subject.name_args << "numCPUs"
      subject.name_args << "42"
      expect(vm).to receive(:ReconfigVM_Task).with(spec: RbVmomi::VIM::VirtualMachineConfigSpec(numCPUs: "42")).and_return(task)
      subject.run
    end

    it "sends two pairs to vsphere" do
      subject.name_args << "numCPUs"
      subject.name_args << "42"
      subject.name_args << "numCoresPerSocket"
      subject.name_args << "6"
      expect(vm).to receive(:ReconfigVM_Task).with(spec: RbVmomi::VIM::VirtualMachineConfigSpec(numCPUs: "42", numCoresPerSocket: "6")).and_return(task)
      subject.run
    end
  end
end
