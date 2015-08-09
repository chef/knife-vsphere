require 'spec_helper'
require 'chef/knife/base_vsphere_command'

describe Chef::Knife::BaseVsphereCommand do
  describe '#password' do
    before do
      expect(subject).to receive(:get_config).with(:vsphere_pass).at_least(:once).and_return(password)
    end

    context 'password is in config file' do
      let(:password) { 'ossifrage' }

      it 'returns the password' do
        expect(subject.password).to eq 'ossifrage'
      end
    end

    context 'password is in config file but encoded' do
      let(:password) { 'base64:c3F1ZWVtaXNo' }

      it 'decodes the password' do
        expect(subject.password).to eq 'squeemish'
      end
    end

    context 'password is not in config file' do
      let(:password) { nil }
      let(:ui) { double( 'Ui', ask: 'passwurd') }

      it 'asks for a password' do
        expect(subject).to receive(:ui).and_return ui
        expect(subject.password).to eq 'passwurd'
      end
    end
  end
end
