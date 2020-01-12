require 'spec_helper'
require 'rspec/its'

describe Puppet::Type.type(:network_config).provider(:redhat) do
  subject { described_class }

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'redhat_spec')
  end

  def fixture_file(file)
    File.join(fixture_path, file)
  end

  def fixture_data(file)
    File.read(fixture_file(file))
  end

  describe 'provider features' do
    it 'is hotpluggable' do
      expect(described_class.declared_feature?(:hotpluggable)).to be true
    end
  end

  describe 'selecting files to parse' do
    subject { described_class.target_files(network_scripts_path).map { |file| File.basename(file) } }

    let(:network_scripts_path) { fixture_file('network-scripts') }

    valid_files = %w[ifcfg-bond0 ifcfg-bond1 ifcfg-eth0 ifcfg-eth1 ifcfg-eth2
                     ifcfg-eth3 ifcfg-vlan100 ifcfg-vlan100:0 ifcfg-vlan200
                     ifcfg-vlan300 ifcfg-vlan400 ifcfg-vlan500 ifcfg-eth0.0
                     ifcfg-eth0.1 ifcfg-eth0.4095 ifcfg-eth0:10000000
                     ifcfg-eth0:my.alias ifcfg-bond1.1001]

    invalid_files = %w[.ifcfg-bond0.swp ifcfg-bond1~ ifcfg-vlan500.bak
                       ifcfg-eth0:my.alias.bak ifcfg-eth0.4096]

    valid_files.each do |file|
      it { is_expected.to include file }
    end

    invalid_files.each do |file|
      it { is_expected.not_to include file }
    end
  end

  describe 'when parsing' do
    describe 'the name' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }

      it { expect(data[:name]).to eq('eth0') }
    end

    describe 'the onboot property' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }

      it { expect(data[:onboot]).to be true }
    end

    describe 'the method property' do
      describe 'when dhcp' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }

        it { expect(data[:method]).to eq('dhcp') }
      end

      describe 'when static' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }

        it { expect(data[:method]).to eq('static') }
      end
    end

    describe 'the hotplug property' do
      describe 'when true' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-hotplug'))[0] }

        it { expect(data[:hotplug]).to be true }
      end

      describe 'when false' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-nohotplug'))[0] }

        it { expect(data[:hotplug]).to be false }
      end
    end

    describe 'a static interface' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }

      it { expect(data[:ipaddress]).to eq('10.0.1.27') }
      it { expect(data[:netmask]).to eq('255.255.255.0') }
    end

    describe 'the options property' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }

      it { expect(data[:options]['USERCTL']).to eq('no') }
      it { expect(data[:options]['NM_CONTROLLED']).to eq('no') }
    end

    describe 'with no extra options' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth1-simple'))[0] }

      it { expect(data[:options]).to eq({}) }
    end

    describe 'complex configuration' do
      let(:virbonding_path) { File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'redhat_spec', 'virbonding') }

      before do
        allow(described_class).to receive(:target_files).and_return(Dir["#{virbonding_path}/*"])
      end

      describe 'bond0' do
        subject { described_class.instances.find { |i| i.name == 'bond0' } }

        its(:onboot) { is_expected.to be true }
        its(:mtu)    { is_expected.to eq('1500') }
        its(:options) do
          is_expected.to eq(
            'BONDING_OPTS' => %(mode=4 miimon=100 xmit_hash_policy=layer3+4)
          )
        end
      end

      describe 'bond1' do
        subject { described_class.instances.find { |i| i.name == 'bond1' } }

        its(:onboot)    { is_expected.to be true }
        its(:ipaddress) { is_expected.to eq('172.20.1.9') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:mtu)       { is_expected.to eq('1500') }
        its(:options) do
          is_expected.to eq(
            'BONDING_OPTS' => %(mode=4 miimon=100 xmit_hash_policy=layer3+4)
          )
        end
      end

      describe 'eth0' do
        subject { described_class.instances.find { |i| i.name == 'eth0' } }

        its(:onboot) { is_expected.to be true }
        its(:mtu)    { is_expected.to eq('1500') }
        its(:mode)   { is_expected.to eq(:raw) }
        its(:options) do
          is_expected.to eq(
            'HWADDR' => '00:12:79:91:28:1f',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond0'
          )
        end
      end

      describe 'eth1' do
        subject { described_class.instances.find { |i| i.name == 'eth1' } }

        its(:onboot) { is_expected.to be true }
        its(:mtu)    { is_expected.to eq('1500') }
        its(:mode)   { is_expected.to eq(:raw) }
        its(:options) do
          is_expected.to eq(
            'HWADDR' => '00:12:79:91:28:20',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond0'
          )
        end
      end

      describe 'eth2' do
        subject { described_class.instances.find { |i| i.name == 'eth2' } }

        its(:onboot) { is_expected.to be true }
        its(:mtu)    { is_expected.to eq('1500') }
        its(:mode)   { is_expected.to eq(:raw) }
        its(:options) do
          is_expected.to eq(
            'HWADDR' => '00:26:55:e9:33:c4',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond1'
          )
        end
      end

      describe 'eth3' do
        subject { described_class.instances.find { |i| i.name == 'eth3' } }

        its(:onboot) { is_expected.to be true }
        its(:mtu)    { is_expected.to eq('1500') }
        its(:mode)   { is_expected.to eq(:raw) }
        its(:options) do
          is_expected.to eq(
            'HWADDR' => '00:26:55:e9:33:c5',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond1'
          )
        end
      end

      describe 'vlan100' do
        subject { described_class.instances.find { |i| i.name == 'vlan100' } }

        its(:ipaddress) { is_expected.to eq('172.24.61.11') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'PHYSDEV'        => 'bond0',
            'GATEWAY'        => '172.24.61.1'
          )
        end
      end

      describe 'vlan100:0' do
        subject { described_class.instances.find { |i| i.name == 'vlan100:0' } }

        its(:ipaddress) { is_expected.to eq('172.24.61.12') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:options)   { is_expected.to eq({}) }
      end

      describe 'vlan200' do
        subject { described_class.instances.find { |i| i.name == 'vlan200' } }

        its(:ipaddress) { is_expected.to eq('172.24.62.1') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'PHYSDEV'        => 'bond0'
          )
        end
      end

      describe 'vlan300' do
        subject { described_class.instances.find { |i| i.name == 'vlan300' } }

        its(:ipaddress) { is_expected.to eq('172.24.63.1') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'PHYSDEV'        => 'bond0'
          )
        end
      end

      describe 'vlan400' do
        subject { described_class.instances.find { |i| i.name == 'vlan400' } }

        its(:ipaddress) { is_expected.to eq('172.24.64.1') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'PHYSDEV'        => 'bond0'
          )
        end
      end

      describe 'vlan500' do
        subject { described_class.instances.find { |i| i.name == 'vlan500' } }

        its(:ipaddress) { is_expected.to eq('172.24.65.1') }
        its(:netmask)   { is_expected.to eq('255.255.255.0') }
        its(:onboot)    { is_expected.to eq(:absent) }
        its(:method)    { is_expected.to eq('static') }
        its(:mode)      { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'PHYSDEV'        => 'bond0'
          )
        end
      end
    end

    describe 'interface.vlan_id vlan configuration' do
      let(:network_scripts_path) { fixture_file('network-scripts') }

      before do
        allow(described_class).to receive(:target_files).and_return(Dir["#{network_scripts_path}/*"])
      end

      describe 'eth0.0' do
        subject { described_class.instances.find { |i| i.name == 'eth0.0' } }

        its(:onboot) { is_expected.to be true }
        its(:method) { is_expected.to eq('static') }
        its(:mtu)    { is_expected.to eq('9000') }
        its(:mode)   { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'IPV6INIT'      => 'no',
            'NM_CONTROLLED' => 'no',
            'TYPE'          => 'Ethernet',
            'BRIDGE'        => 'br1'
          )
        end
      end

      describe 'eth0.1' do
        subject { described_class.instances.find { |i| i.name == 'eth0.1' } }

        its(:onboot) { is_expected.to be true }
        its(:method) { is_expected.to eq('static') }
        its(:mtu)    { is_expected.to eq('9000') }
        its(:mode)   { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'IPV6INIT'      => 'no',
            'NM_CONTROLLED' => 'no',
            'TYPE'          => 'Ethernet',
            'BRIDGE'        => 'br1'
          )
        end
      end

      describe 'eth0.4095' do
        subject { described_class.instances.find { |i| i.name == 'eth0.4095' } }

        its(:onboot) { is_expected.to be true }
        its(:method) { is_expected.to eq('static') }
        its(:mtu)    { is_expected.to eq('9000') }
        its(:mode)   { is_expected.to eq(:vlan) }
        its(:options) do
          is_expected.to eq(
            'IPV6INIT'      => 'no',
            'NM_CONTROLLED' => 'no',
            'TYPE'          => 'Ethernet',
            'BRIDGE'        => 'br4095'
          )
        end
      end
    end

    describe 'when reading an invalid interfaces' do
      it 'with a mangled key/value should fail' do
        expect { described_class.parse_file('eth0', 'DEVICE: eth0') }.to raise_error Puppet::Error, %r{malformed}
      end
    end

    describe 'when DEVICE is not present' do
      let(:data) { described_class.parse_file('ifcfg-eth1', fixture_data('eth1-dhcp'))[0] }

      it { expect(data[:name]).to eq('eth1') }
    end
  end

  describe 'when formatting resources' do
    let(:eth0_provider) do
      instance_double('eth0_provider',
                      name: 'eth0',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'none',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.255.0',
                      mtu: '1500',
                      mode: nil,
                      options: { 'NM_CONTROLLED' => 'no', 'USERCTL' => 'no' })
    end

    let(:eth0_1_provider) do
      instance_double('eth0_1_provider',
                      name: 'eth0.1',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'none',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.255.0',
                      mtu: '1500',
                      mode: :vlan,
                      options: { 'NM_CONTROLLED' => 'no', 'USERCTL' => 'no' })
    end

    let(:eth1_provider) do
      instance_double('eth1_provider',
                      name: 'eth1',
                      ensure: :present,
                      onboot: :absent,
                      hotplug: true,
                      family: 'inet',
                      method: 'none',
                      ipaddress: :absent,
                      netmask: :absent,
                      mtu: :absent,
                      mode: :vlan,
                      options: :absent)
    end

    let(:lo_provider) do
      instance_double('lo_provider',
                      name: 'lo',
                      onboot: true,
                      hotplug: true,
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
                      onboot: true,
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

      it { expect(data).to match(%r{DEVICE=eth0}) }
      it { expect(data).to match(%r{ONBOOT=yes}) }
      it { expect(data).to match(%r{BOOTPROTO=none}) }
      it { expect(data).to match(%r{IPADDR=169\.254\.0\.1}) }
      it { expect(data).to match(%r{NETMASK=255\.255\.255\.0}) }
      it { expect(data).to match(%r{NM_CONTROLLED=no}) }
      it { expect(data).to match(%r{USERCTL=no}) }
      # XXX should be be always managing VLAN?
      it { expect(data).not_to match(%r{VLAN=yes}) }
      it { expect(data).not_to match(%r{VLAN=no}) }
    end

    describe 'with test interface eth0.1' do
      let(:data) { described_class.format_file('filepath', [eth0_1_provider]) }

      it { expect(data).to match(%r{DEVICE=eth0.1}) }
      it { expect(data).to match(%r{ONBOOT=yes}) }
      it { expect(data).to match(%r{BOOTPROTO=none}) }
      it { expect(data).to match(%r{IPADDR=169\.254\.0\.1}) }
      it { expect(data).to match(%r{NETMASK=255\.255\.255\.0}) }
      it { expect(data).to match(%r{NM_CONTROLLED=no}) }
      it { expect(data).to match(%r{USERCTL=no}) }
      it { expect(data).to match(%r{VLAN=yes}) }
    end

    describe 'with test interface eth1' do
      let(:data) { described_class.format_file('filepath', [eth1_provider]) }

      it { expect(data).to match(%r{DEVICE=eth1}) }
      it { expect(data).to match(%r{VLAN=yes}) }
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
