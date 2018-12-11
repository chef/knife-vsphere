require "spec_helper"
require "chef/knife/vsphere_vlan_list"

describe Chef::Knife::VsphereVlanList do
  let(:datacenter) { double("Datacenter") }
  let(:n1) { double("Network", name: "n1") }
  let(:n2) { double("Network", name: "n2") }

  subject { described_class.new }

  it "enumerates the vlans" do
    expect(subject).to receive(:vim_connection)
    expect(subject).to receive(:datacenter).and_return(datacenter)
    expect(datacenter).to receive(:network).and_return([n1, n2])
    expect(n1).to receive :name
    expect(n2).to receive :name
    expect(subject).to receive(:puts).twice

    subject.run
  end
end
