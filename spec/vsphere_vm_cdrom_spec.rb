require 'spec_helper'
require 'chef/knife/vsphere_vm_cdrom'

describe Chef::Knife::VsphereVmCdrom do
  include_context 'stub_vm_search'

  let(:vm) { double('VM') }

  let(:config) { double('Config', hardware: hardware) }
  let(:hardware) { double('Hardware', device: devices) }
  let(:devices) { double('Devices') }
  let(:cd_rom) { double('CDROM', key: 'key', controllerKey: 'controllerKey') }
  let(:task) { double('Task', wait_for_completion: true) }

  before do
    allow(devices).to receive(:find).and_return(cd_rom)
    allow(subject).to receive(:find_in_folder).and_return(vm)
    allow(vm).to receive(:config).and_return(config)
    subject.name_args = ['foo']
  end

  context 'input sanity' do
    it 'rejects both mount and disconnect' do
      subject.config[:attach] = true
      subject.config[:disconnect] = true
      expect { subject.run }.to raise_error SystemExit
    end

    it 'requires a data store and iso to mount' do
      subject.config[:attach] = true
      expect { subject.run }.to raise_error SystemExit
    end
  end

  context 'mount' do
    before do
      subject.config[:attach] = true
    end

    context 'with correct options' do
      before do
        subject.config[:datastore] = 'datastore'
        subject.config[:iso] = 'iso'
      end

      it 'mounts the drive' do
        expect(vm).to receive(:ReconfigVM_Task) do |args|
          spec = args[:spec]
          expect(spec.deviceChange).to be_an(Array)
          op = spec.deviceChange.first

          expect(op[:operation]).to eq(:edit)
          expect(op[:device].key).to eq('key')
          expect(op[:device].controllerKey).to eq('controllerKey')
          expect(op[:device].connectable).to be_an_instance_of RbVmomi::VIM::VirtualDeviceConnectInfo
          expect(op[:device].connectable.allowGuestControl).to be true
        end.and_return(task)
        subject.run
      end

      it 'uses a VirtualCdromIsoBackingInfo' do
        # TODO: Figure out why mounting uses one type and disconnecting the other
        expect(vm).to receive(:ReconfigVM_Task) do |args|
          spec = args[:spec]
          op = spec.deviceChange.first

          expect(op[:device].backing).to be_an_instance_of RbVmomi::VIM::VirtualCdromIsoBackingInfo
          expect(op[:device].backing.fileName).to eq('[datastore] iso')
        end.and_return(task)
        subject.run
      end
    end

    context 'there is no cd drive' do
      let(:cd_rom) { nil }

      it 'exits gracefully' do
        subject.config[:datastore] = 'datastore'
        subject.config[:iso] = 'iso'
        expect { subject.run }.to raise_error SystemExit
      end
    end
  end

  context 'disconnect' do
    before do
      subject.config[:disconnect] = true
    end

    context 'with correct options' do
      it 'disconnects the drive' do
        expect(vm).to receive(:ReconfigVM_Task) do |args|
          spec = args[:spec]
          expect(spec.deviceChange).to be_an(Array)
          op = spec.deviceChange.first

          expect(op[:operation]).to eq(:edit)
          expect(op[:device].key).to eq('key')
          expect(op[:device].controllerKey).to eq('controllerKey')
          expect(op[:device].connectable).to be_an_instance_of RbVmomi::VIM::VirtualDeviceConnectInfo
          expect(op[:device].connectable.allowGuestControl).to be true
        end.and_return(task)
        subject.run
      end

      it 'uses a VirtualCdromIsoBackingInfo' do
        # TODO: Figure out why mounting uses one type and disconnecting the other
        expect(vm).to receive(:ReconfigVM_Task) do |args|
          spec = args[:spec]
          op = spec.deviceChange.first

          expect(op[:device].backing).to be_an_instance_of RbVmomi::VIM::VirtualCdromRemoteAtapiBackingInfo
          expect(op[:device].backing.deviceName).to eq('')
        end.and_return(task)
        subject.run
      end
    end

    context 'there is no cd drive' do
      let(:cd_rom) { nil }

      it 'exits gracefully' do
        subject.config[:datastore] = 'datastore'
        subject.config[:iso] = 'iso'
        expect { subject.run }.to raise_error SystemExit
      end
    end
  end
end
