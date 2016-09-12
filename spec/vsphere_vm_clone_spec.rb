require 'spec_helper'
require 'chef/knife/vsphere_vm_clone'

describe Chef::Knife::VsphereVmClone do
  let(:datacenter) { double('Datacenter', vmFolder: empty_folder, hostFolder: empty_folder) }
  let(:empty_folder) { double('Folder', childEntity: [], children: []) }
  let(:host) { double('Host', resourcePool: double('ResourcePool')) }
  let(:root_folder) { double('RootFolder', children: []) }
  let(:service_content) { double('ServiceContent') }
  let(:task) { double('Task', wait_for_completion: 'done') }
  let(:template) { double('Template', config: double(guestId: 'Linux')) }
  let(:vim) { double('VimConnection', serviceContent: service_content) }

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
      subject.name_args = ['foo']
      expect(subject).to receive(:vim_connection).and_raise ArgumentError
      expect { subject.run }.to raise_error ArgumentError
    end
  end

  context 'customizing the mac' do
    before do
      allow(subject).to receive(:vim_connection).and_return(vim)
      # It is difficult to mock this because the current implementation checks
      # for explicity RbVmomi class names
      allow(subject).to receive(:datacenter).and_return(datacenter)
      allow(subject).to receive(:find_available_hosts).and_return([host])

      allow(service_content).to receive(:virtualDiskManager) # what does this call actually do?
      subject.config[:folder] = ''
      subject.config[:source_vm] = 'my_template'
    end

    context 'the mac is given' do
      it 'requires an ip' do
        subject.name_args = ['foo']
        subject.config[:customization_macs] = '00:11:22:33:44:55'

        expect { subject.run }.to raise_error SystemExit
      end
    end

    context 'the mac is not given' do
      before do
        subject.name_args = ['foo']

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
    include_context 'basic_setup'

    context 'naming the vm in the identity' do
      context 'no name is passed' do
        it 'should use the vmname in the identity' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization.identity.hostName.name).to eq 'foo'
          end.and_return(task)

          subject.run
        end
      end

      context 'customization_hostname is passed' do
        before do
          subject.config[:customization_hostname] = 'bar'
        end

        it 'should use the passed name in the identity' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization.identity.hostName.name).to eq 'bar'
          end.and_return(task)

          subject.run
        end

        it 'has a blank domain name' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization.identity.domain).to eq ''
          end.and_return(task)

          subject.run
        end
      end

      context 'customization_domain is passed' do
        before do
          subject.config[:customization_domain] = 'example.com'
        end

        it 'should use the vmname' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization.identity.hostName.name).to eq 'foo'
          end.and_return(task)

          subject.run
        end

        it 'adds the domain name to the spec' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization.identity.domain).to eq 'example.com'
          end.and_return(task)

          subject.run
        end
      end
    end

    context 'customizations disabled' do
      before do
        subject.config[:disable_customization] = true
      end

      it 'sends no customization' do
        expect(template).to receive(:CloneVM_Task) do |args|
          expect(args[:spec].customization).to be_nil
        end.and_return(task)

        subject.run
      end

      it 'does not power on by default' do
        expect(template).to receive(:CloneVM_Task) do |args|
          expect(args[:spec].powerOn).to eq(false)
        end.and_return(task)

        subject.run
      end

      context 'also asking for a cspec' do
        before do
          subject.config[:customization_spec] = 'cspec'
          allow(service_content).to receive(:customizationSpecManager).and_return(csm)
        end

        let(:csm) { double('CustomizationSpecManager', GetCustomizationSpec: cspec) }
        let(:cspec) { double('Cspec', spec: spec) }
        let(:spec) { double('Specification') }

        it 'sends that spec in' do
          expect(template).to receive(:CloneVM_Task) do |args|
            expect(args[:spec].customization).to eq(spec)
          end.and_return(task)

          subject.run
        end
      end
    end

    context 'windows clone' do
      before do
        let(:guest_id) { 'Windows 3.1' }
      end
    end
    context 'linux clone'
    context 'neither windows or linux' do
      before do
        let(:guest_id) { 'Darwin' }
      end
    end
  end
end
