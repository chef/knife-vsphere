require "spec_helper"
require "chef/knife/base_vsphere_command"

describe Chef::Knife::BaseVsphereCommand do
  describe "#password" do
    before do
      expect(subject).to receive(:get_config).with(:vsphere_pass).at_least(:once).and_return(password)
    end

    context "password is in config file" do
      let(:password) { "ossifrage" }

      it "returns the password" do
        expect(subject.password).to eq "ossifrage"
      end
    end

    context "password is in config file but encoded" do
      let(:password) { "base64:c3F1ZWVtaXNo" }

      it "decodes the password" do
        expect(subject.password).to eq "squeemish"
      end
    end

    context "password is not in config file" do
      let(:password) { nil }
      let(:ui) { double("Ui", ask: "passwurd") }

      it "asks for a password" do
        expect(subject).to receive(:ui).and_return ui
        expect(subject.password).to eq "passwurd"
      end
    end
  end

  describe "#conn_opts" do
    let(:ui) { double("Ui", ask: "passwurd") }

    let(:config) do
      { vsphere_host: "hostname",
        vsphere_path: "path",
        vsphere_port: "port",
        vsphere_nossl: true,
        vsphere_user: "user",
        vsphere_pass: "password",
        vsphere_insecure: false,
        proxy_host: "proxyhost",
        proxy_port: "proxyport" }
    end

    before do
      allow(subject).to receive(:get_config) do |option|
        config[option]
      end
    end

    it "includes the host" do
      expect(subject.conn_opts).to include(host: "hostname")
    end

    it "includes the path" do
      expect(subject.conn_opts).to include(path: "path")
    end

    it "includes the path" do
      expect(subject.conn_opts).to include(port: "port")
    end

    it "includes whether or not to use ssl" do
      expect(subject.conn_opts).to include(use_ssl: false)
    end

    it "includes the user" do
      expect(subject.conn_opts).to include(user: "user")
    end

    it "includes the password" do
      expect(subject.conn_opts).to include(password: "password")
    end

    it "includes whether or not to ignore certificates" do
      expect(subject.conn_opts).to include(insecure: false)
    end

    it "includes the proxy host" do
      expect(subject.conn_opts).to include(proxyHost: "proxyhost")
    end

    it "includes the proxy port" do
      expect(subject.conn_opts).to include(proxyPort: "proxyport")
    end
  end
end
