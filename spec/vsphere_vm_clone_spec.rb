require 'spec_helper'
require 'chef/knife/vsphere_vm_clone'
require 'chef/knife/bootstrap'

class Fakey
  def initialize(data)
    @data = data
  end

  def props
    @data.keys
  end

  def method_missing(element)
    desired = @data[element]
    if desired.is_a? Hash
      self.class.new(desired)
    else
      desired
    end
  end
end

describe Chef::Knife::VsphereVmClone do
  let(:datacenter) { double('Datacenter', vmFolder: empty_folder, hostFolder: empty_folder) }
  let(:empty_folder) { double('Folder', childEntity: [], children: []) }
  let(:host) { double('Host', resourcePool: double('ResourcePool')) }
  #let(:root_folder) { double('RootFolder', children: []) }
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
    allow(subject).to receive(:get_vm_by_name).with('my_template', '').and_return(template)
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

  context 'cloning to a specific host' do
    include_context 'basic_setup'

    let(:desired_host) { 'myhost' }

    before do
      subject.config[:host] = desired_host
      expect(subject).to receive(:find_host).with(desired_host).and_return(host)
    end

    it 'creates a specification that clones to the given host' do
      expect(template).to receive(:CloneVM_Task) do |args|
        expect(args[:spec].location.host).to eq host
      end.and_return(task)
      subject.run
    end

    it 'requires a pool' do
      expect(template).to receive(:CloneVM_Task) do |args|
        expect(args[:spec].location.pool).to eq pool
      end.and_return(task)
      subject.run
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

  context 'error handling' do
    include_context 'basic_setup'

    context 'user attempts to clone a box with the wrong number of nics configured' do
      it 'should provide a helpful message' do
        expect(template).to receive(:CloneVM_Task).and_return(task)
        expect(task).to receive(:wait_for_completion) {
          fault = RbVmomi::VIM::NicSettingMismatch.new(numberOfNicsInVM: 1, numberOfNicsInSpec: 2)
          raise RbVmomi::Fault.new('fault.NicSettingMismatch.summary', fault)
        }
        expect { subject.run }.to raise_error SystemExit

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
      let(:csm) { double('CustomizationSpecManager', GetCustomizationSpec: server_spec) }
      let(:server_spec) { double('Cspec', spec: spec) }
      let(:guest_id) { 'Windows 3.1' }
      let(:spec) { double('Specification', identity: Fakey.new(identity)) }
      let(:identity) { { identification: { joinWorkgroup: true },
                         licenseFilePrintData: { autoMode: true },
                         userData: { fullName: 'Chefy McChef' },
                         guiUnattended: { autoLogon: true,
                                          password: { plainText: 'plaintextpassword'} } }
      }


      it 'provides an error message when called with no customization' do
        expect(subject).to receive(:fatal_exit).and_raise ArgumentError
        expect { subject.run }.to raise_error ArgumentError
      end

      context 'with a cspec' do
        before do
          subject.config[:customization_hostname] = 'myhost'
          subject.config[:customization_spec] = 'cspec'
          allow(service_content).to receive(:customizationSpecManager).and_return(csm)
        end

        it 'overrides the hostname and command list' do
          expect(template).to receive(:CloneVM_Task).and_return(task)

          expect(spec).to receive(:'identity=') do |args|
            expect(args.guiRunOnce.commandList).to eq ['cust_spec.identity.guiUnattended.commandList']
            expect(args.userData.computerName.name).to eq('myhost')
          end
          subject.run
        end

        it 'uses a sysprep identity' do
          expect(template).to receive(:CloneVM_Task).and_return(task)
          expect(spec).to receive(:'identity=') do |args|
            expect(args).to be_a RbVmomi::VIM::CustomizationSysprep
          end
          subject.run
        end

        context 'that doesnt provide license data' do
          let(:identity) { { identification: { joinWorkgroup: true },
                             userData: { fullName: 'Chefy McChef' },
                             guiUnattended: { autoLogon: true,
                                              password: { plainText: 'plaintextpassword'} } }
          }
          it 'successfully clones' do
            expect(template).to receive(:CloneVM_Task).and_return(task)

            expect(spec).to receive(:'identity=') do |args|
              expect(args.licenseFilePrintData).to be_nil
            end
            subject.run
          end
        end

        context 'that provides customization domain' do
          before do
            subject.config[:customization_domain] = 'example.com'
          end

          context 'matching customization spec' do
            let(:identity) { { identification: { joinDomain: 'example.com' },
                               licenseFilePrintData: { autoMode: true },
                               userData: { fullName: 'Chefy McChef' },
                               guiUnattended: { autoLogon: true,
                                                password: { plainText: 'plaintextpassword'} } }
            }

            it 'successfully clones with joinDomain set to customization domain' do
              expect(template).to receive(:CloneVM_Task).and_return(task)
              expect(spec).to receive(:'identity=') do |args|
                expect(args.identification.joinDomain).to eq('example.com')
              end
              subject.run
            end
          end

          context 'not matching customization spec' do
            let(:identity) { { identification: { joinDomain: 'example2.com' },
                               licenseFilePrintData: { autoMode: true },
                               userData: { fullName: 'Chefy McChef' },
                               guiUnattended: { autoLogon: true,
                                                password: { plainText: 'plaintextpassword'} } }
            }

            it 'successfully clones with joinDomain set to customization domain' do
              expect(template).to receive(:CloneVM_Task).and_return(task)
              expect(spec).to receive(:'identity=') do |args|
                expect(args.identification.joinDomain).to eq('example.com')
              end
              subject.run
            end
          end
        end
      end
    end

    context 'linux clone'
    context 'neither windows or linux' do
      before do
        let(:guest_id) { 'Darwin' }
      end
    end
  end

  context 'bootstrapping chef' do
    include_context 'basic_setup'

    let(:chef) { OpenStruct.new(config: {}, run: 'boom') }
    let(:guest) { double('Guest', net: [:thing], ipAddress: '1.2.3.4') }

    before do
      subject.config[:bootstrap] = true
      allow(subject).to receive(:get_vm_by_name).with('foo', '').and_return(guest)
      allow(guest).to receive(:PowerOnVM_Task).and_return(task)
      allow(guest).to receive(:guest).and_return(guest)
      allow(subject).to receive(:tcp_test_ssh).with('foo.bar', 22).and_return(true) # cheat

      expect(Chef::Knife::Bootstrap).to receive(:new).and_return(chef)
      expect(template).to receive(:CloneVM_Task).and_return(task)
    end

    context 'with an fqdn' do
      before do
        subject.config[:fqdn] = 'foo.bar'
      end

      it 'calls Chef to bootstrap' do
        expect(chef).to receive(:run) do
          expect(chef.name_args).to eq(['foo.bar'])
        end

        subject.run
      end

      it 'sends the runlist' do
        subject.config[:run_list] = %w{role[a] recipe[foo::bar]}
        expect(chef).to receive(:run) do
          expect(chef.config[:run_list]).to eq(%w{role[a] recipe[foo::bar]})
        end

        subject.run
      end
    end

    context 'handing over tags' do
      before do
        # Avoid the complexity inside `guest_address`
        subject.config[:fqdn] = 'foo.bar'
      end

      context 'without tags' do
        it 'does not set any tags' do
          expect(chef).to receive(:run) do
            expect(chef.config[:tags]).to eq([])
          end

          subject.run
        end
      end

      context 'with tags' do
        before do
          subject.config[:tags] = %w(tag1 tag2)
        end

        it 'sends the tags to the bootstrap' do
          expect(chef).to receive(:run) do
            expect(chef.config[:tags]).to eq(%w(tag1 tag2))
          end

          subject.run
        end
      end
    end
  end
end
