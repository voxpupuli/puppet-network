require 'spec_helper'
require 'rspec/its'

describe Puppet::Type.type(:network_config).provider(:sles) do
  subject { described_class }

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'sles_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
    File.read(fixture_file(file))
  end

  describe 'provider features' do
    it 'is not hotpluggable' do
      expect(described_class.declared_feature?(:hotpluggable)).to be false
    end

    it 'is startmode' do
      expect(described_class.declared_feature?(:startmode)).to be true
    end
  end

  describe 'selecting files to parse' do
    subject { described_class.target_files(network_scripts_path).map { |file| File.basename(file) } }

    let(:network_scripts_path) { fixture_file('network-scripts') }

    valid_files = %w[ifcfg-bond0 ifcfg-bond1 ifcfg-eth0 ifcfg-eth1 ifcfg-eth2
                     ifcfg-eth3 ifcfg-vlan100 ifcfg-vlan200
                     ifcfg-eth0.4095 ifcfg-bond1.1001]

    invalid_files = %w[.ifcfg-bond0.swp ifcfg-bond1~ ifcfg-vlan500.bak
                       ifcfg-eth0_my.alias.bak ifcfg-eth0.4096]

    valid_files.each do |file|
      it { is_expected.to include file }
    end

    invalid_files.each do |file|
      it { is_expected.not_to include file }
    end
  end

  describe 'when parsing' do
    describe 'the name' do
      let(:data) { described_class.parse_file('ifcfg-eth0', fixture_data('ifcfg-eth0-dhcp'))[0] }

      it { expect(data[:name]).to eq('eth0') }
    end

    describe 'the startmode property' do
      let(:data) { described_class.parse_file('ifcfg-eth0', fixture_data('ifcfg-eth0-dhcp'))[0] }

      it { expect(data[:startmode]).to eq('auto') }
    end

    describe 'the bootproto property' do
      describe 'when dhcp' do
        let(:data) { described_class.parse_file('ifcfg-eth0', fixture_data('ifcfg-eth0-dhcp'))[0] }

        it { expect(data[:method]).to eq('dhcp') }
      end

      describe 'when static' do
        let(:data) { described_class.parse_file('ifcfg-eth0', fixture_data('ifcfg-eth0-static'))[0] }

        it { expect(data[:method]).to eq('static') }
      end
    end

    describe 'a static interface' do
      let(:data) { described_class.parse_file('eth0', fixture_data('ifcfg-eth0-static'))[0] }

      it { expect(data[:ipaddress]).to eq('10.0.1.27') }
      it { expect(data[:netmask]).to eq('255.255.255.0') }
    end

    describe 'the options property' do
      let(:data) { described_class.parse_file('eth0', fixture_data('ifcfg-eth0-static'))[0] }

      it { expect(data[:options]['LLADDR']).to eq('aa:bb:cc:dd:ee:ff') }
    end

    describe 'with no extra options' do
      let(:data) { described_class.parse_file('eth0', fixture_data('ifcfg-eth1-simple'))[0] }

      it { expect(data[:options]).to eq({}) }
    end

    describe 'complex configuration' do
      let(:virbonding_path) { File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'sles_spec', 'virbonding') }

      before do
        allow(described_class).to receive(:target_files).and_return(Dir["#{virbonding_path}/*"])
      end

      describe 'bond0' do
        subject { described_class.instances.find { |i| i.name == 'bond0' } }

        its(:startmode) { is_expected.to eq('auto') }
        its(:mtu)       { is_expected.to eq('1500') }

        its(:options) do
          is_expected.to eq(
            'BONDING_MASTER'      => 'yes',
            'BONDING_MODULE_OPTS' => %(mode=4 miimon=100 xmit_hash_policy=layer3+4),
            'BONDING_SLAVE_0'     => 'eth0',
            'BONDING_SLAVE_1'     => 'eth1'
          )
        end
      end

      describe 'bond1' do
        subject { described_class.instances.find { |i| i.name == 'bond1' } }

        its(:startmode) { is_expected.to eq('auto') }
        its(:ipaddress) { is_expected.to eq('172.20.1.9') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:mtu)       { is_expected.to eq('1500') }

        its(:options) do
          is_expected.to eq(
            'BONDING_MASTER'      => 'yes',
            'BONDING_MODULE_OPTS' => %(mode=4 miimon=100 xmit_hash_policy=layer3+4),
            'BONDING_SLAVE_0'     => 'eth2',
            'BONDING_SLAVE_1'     => 'eth3'
          )
        end
      end

      describe 'eth0' do
        subject { described_class.instances.find { |i| i.name == 'eth0' } }

        its(:startmode) { is_expected.to eq('hotplug') }
        its(:mtu)       { is_expected.to eq('1500') }
        its(:mode)      { is_expected.to eq(:raw) }

        its(:options) do
          is_expected.to eq(
            'LLADDR' => '00:12:79:91:28:1f'
          )
        end
      end

      describe 'eth1' do
        subject { described_class.instances.find { |i| i.name == 'eth1' } }

        its(:startmode) { is_expected.to eq('hotplug') }
        its(:mtu)       { is_expected.to eq('1500') }
        its(:mode)      { is_expected.to eq(:raw) }

        its(:options) do
          is_expected.to eq(
            'LLADDR' => '00:12:79:91:28:20'
          )
        end
      end

      describe 'eth2' do
        subject { described_class.instances.find { |i| i.name == 'eth2' } }

        its(:startmode) { is_expected.to eq('hotplug') }
        its(:mtu)       { is_expected.to eq('1500') }
        its(:mode)      { is_expected.to eq(:raw) }

        its(:options) do
          is_expected.to eq(
            'LLADDR' => '00:26:55:e9:33:c4'
          )
        end
      end

      describe 'eth3' do
        subject { described_class.instances.find { |i| i.name == 'eth3' } }

        its(:startmode) { is_expected.to eq('hotplug') }
        its(:mtu)       { is_expected.to eq('1500') }
        its(:mode)      { is_expected.to eq(:raw) }

        its(:options) do
          is_expected.to eq(
            'LLADDR' => '00:26:55:e9:33:c5'
          )
        end
      end

      describe 'vlan100' do
        subject { described_class.instances.find { |i| i.name == 'vlan100' } }

        its(:ipaddress) { is_expected.to eq('172.24.61.11') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:startmode) { is_expected.to eq('off') }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }

        its(:options) do
          is_expected.to eq(
            'ETHERDEVICE' => 'bond0'
          )
        end
      end

      describe 'vlan200' do
        subject { described_class.instances.find { |i| i.name == 'vlan200' } }

        its(:ipaddress) { is_expected.to eq('172.24.62.1') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:startmode) { is_expected.to eq('off') }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }

        its(:options) do
          is_expected.to eq(
            'ETHERDEVICE' => 'bond0'
          )
        end
      end
    end

    describe 'interface.vlan_id vlan configuration' do
      let(:network_scripts_path) { fixture_file('network-scripts') }

      before do
        allow(described_class).to receive(:target_files).and_return(Dir["#{network_scripts_path}/*"])
      end

      describe 'eth0.4095' do
        subject { described_class.instances.find { |i| i.name == 'eth0.4095' } }

        its(:startmode) { is_expected.to eq('auto') }
        its(:method)    { is_expected.to eq('static') }
        its(:mtu)       { is_expected.to eq('9000') }
        its(:mode)      { is_expected.to eq(:vlan) }

        its(:options) do
          is_expected.to eq(
            'INTERFACETYPE' => 'Ethernet',
            'ETHERDEVICE' => 'br4095'
          )
        end
      end
    end

    describe 'when DEVICE is not present' do
      let(:data) { described_class.parse_file('ifcfg-eth1', fixture_data('ifcfg-eth1-dhcp'))[0] }

      it { expect(data[:name]).to eq('eth1') }
    end
  end

  describe 'when formatting resources' do
    let(:eth0_provider) do
      instance_double('eth0_provider',
                      name: 'eth0',
                      ensure: :present,
                      startmode: 'auto',
                      hotplug: true,
                      family: 'inet',
                      method: 'none',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.255.0',
                      mtu: '1500',
                      mode: nil,
                      options: {})
    end

    let(:eth0_1_provider) do
      instance_double('eth0_1_provider',
                      name: 'eth0.1',
                      ensure: :present,
                      startmode: 'auto',
                      family: 'inet',
                      method: 'none',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.255.0',
                      mtu: '1500',
                      mode: :vlan,
                      options: {})
    end

    let(:eth1_provider) do
      instance_double('eth1_provider',
                      name: 'eth1',
                      etherdevice: 'eth1',
                      ensure: :present,
                      startmode: 'off',
                      family: 'inet',
                      method: 'none',
                      ipaddress: :absent,
                      netmask: :absent,
                      mtu: :absent,
                      mode: :vlan,
                      options: {
                        'ETHERDEVICE' => 'eth1'
                      })
    end

    let(:lo_provider) do
      instance_double('lo_provider',
                      name: 'lo',
                      startmode: 'yes',
                      family: 'inet',
                      method: 'loopback',
                      ipaddress: nil,
                      netmask: nil,
                      mode: nil,
                      options: {})
    end

    let(:bond0_provider) do
      instance_double('bond0_provider',
                      name: 'bond0',
                      startmode: 'auto',
                      hotplug: true,
                      ipaddress: '172.20.1.9',
                      netmask: '255.255.255.0',
                      method: 'static',
                      mtu: '1500',
                      mode: nil,
                      options: {
                        'BONDING_OPTS' => %(mode=4 miimon=100 xmit_hash_policy=layer3+4)
                      })
    end

    it 'fails if multiple interfaces are flushed to one file' do
      expect { described_class.format_file('filepath', [eth0_provider, lo_provider]) }.to raise_error Puppet::DevError, %r{multiple interfaces}
    end

    describe 'with test interface eth0' do
      let(:data) { described_class.format_file('filepath', [eth0_provider]) }

      it { expect(data).to match(%r{STARTMODE=auto}) }
      it { expect(data).to match(%r{BOOTPROTO=none}) }
      it { expect(data).to match(%r{IPADDR=169\.254\.0\.1}) }
      it { expect(data).to match(%r{NETMASK=255\.255\.255\.0}) }
    end

    describe 'with test interface eth0.1' do
      let(:data) { described_class.format_file('filepath', [eth0_1_provider]) }

      it { expect(data).to match(%r{STARTMODE=auto}) }
      it { expect(data).to match(%r{BOOTPROTO=none}) }
      it { expect(data).to match(%r{IPADDR=169\.254\.0\.1}) }
      it { expect(data).to match(%r{NETMASK=255\.255\.255\.0}) }
    end

    describe 'with test interface eth1' do
      let(:data) { described_class.format_file('filepath', [eth1_provider]) }

      it { expect(data).to match(%r{ETHERDEVICE=eth1}) }
      it { expect(data).to match(%r{BOOTPROTO=none}) }
      it { expect(data).to match(%r{STARTMODE=off}) }
      it { expect(data).not_to match(%r{absent}) }
    end

    describe 'with test interface bond0' do
      let(:data) { described_class.format_file('filepath', [bond0_provider]) }

      it { expect(data).to match(%r{BONDING_OPTS="mode=4 miimon=100 xmit_hash_policy=layer3\+4"}) }
    end
  end

  describe 'when flushing a dirty file' do
    before do
      allow(File).to receive(:chmod).with(0o644, '/not/a/real/file')
      allow(File).to receive(:unlink)
      allow(described_class).to receive(:perform_write)
    end

    it do
      described_class.dirty_file!('/not/a/real/file')
      described_class.flush_file('/not/a/real/file')
    end

    it 'is expected that it shouldnot have have unlinked the file' do
      expect(File).not_to have_received(:unlink)
    end
  end
end
