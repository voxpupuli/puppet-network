require 'spec_helper'
require 'rspec/its'

describe Puppet::Type.type(:network_config).provider(:nm) do
  subject { described_class }

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'nm_spec')
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

    it 'supports provider options' do
      expect(described_class.declared_feature?(:provider_options)).to be true
    end

    it 'is reconfigurable' do
      expect(described_class.declared_feature?(:reconfigurable)).to be true
    end
  end

  describe 'confines and defaults' do
    before do
      allow(File).to receive(:executable?).and_call_original
    end

    context 'when nmstatectl is available' do
      before do
        allow(File).to receive(:executable?).with('/usr/bin/nmstatectl').and_return(true)
        allow(Facter).to receive(:value).with(:service_provider).and_return('systemd')
      end

      it 'is suitable' do
        expect(described_class.suitable?).to be true
      end
    end

    context 'when nmstatectl is not available' do
      before do
        allow(File).to receive(:executable?).with('/usr/bin/nmstatectl').and_return(false)
        allow(File).to receive(:executable?).with('/usr/local/bin/nmstatectl').and_return(false)
      end

      it 'is not suitable' do
        expect(described_class.suitable?).to be false
      end
    end
  end

  describe '.prefix_to_netmask' do
    it 'converts /24 to 255.255.255.0' do
      expect(described_class.prefix_to_netmask(24)).to eq('255.255.255.0')
    end

    it 'converts /16 to 255.255.0.0' do
      expect(described_class.prefix_to_netmask(16)).to eq('255.255.0.0')
    end

    it 'converts /8 to 255.0.0.0' do
      expect(described_class.prefix_to_netmask(8)).to eq('255.0.0.0')
    end

    it 'handles nil input' do
      expect(described_class.prefix_to_netmask(nil)).to be_nil
    end
  end

  describe '#netmask_to_prefix' do
    let(:provider) { described_class.new(name: 'eth0') }

    it 'converts 255.255.255.0 to /24' do
      expect(provider.netmask_to_prefix('255.255.255.0')).to eq(24)
    end

    it 'converts 255.255.0.0 to /16' do
      expect(provider.netmask_to_prefix('255.255.0.0')).to eq(16)
    end

    it 'converts 255.0.0.0 to /8' do
      expect(provider.netmask_to_prefix('255.0.0.0')).to eq(8)
    end

    it 'handles nil input' do
      expect(provider.netmask_to_prefix(nil)).to be_nil
    end
  end

  describe '#determine_interface_type' do
    let(:provider) { described_class.new(name: interface_name) }

    context 'with ethernet interface names' do
      %w[eth0 eth1 enp0s3 ens33].each do |name|
        context "with #{name}" do
          let(:interface_name) { name }

          it 'returns ethernet' do
            expect(provider.send(:determine_interface_type)).to eq('ethernet')
          end
        end
      end
    end

    context 'with wireless interface names' do
      %w[wlan0 wlp2s0].each do |name|
        context "with #{name}" do
          let(:interface_name) { name }

          it 'returns wifi' do
            expect(provider.send(:determine_interface_type)).to eq('wifi')
          end
        end
      end
    end

    context 'with bond interface names' do
      %w[bond0 bond1].each do |name|
        context "with #{name}" do
          let(:interface_name) { name }

          it 'returns bond' do
            expect(provider.send(:determine_interface_type)).to eq('bond')
          end
        end
      end
    end

    context 'with bridge interface names' do
      %w[br0 bridge0].each do |name|
        context "with #{name}" do
          let(:interface_name) { name }

          it 'returns linux-bridge' do
            expect(provider.send(:determine_interface_type)).to eq('linux-bridge')
          end
        end
      end
    end

    context 'with VLAN interface names' do
      ['eth0.100', 'ens33.200'].each do |name|
        context "with #{name}" do
          let(:interface_name) { name }

          it 'returns vlan' do
            expect(provider.send(:determine_interface_type)).to eq('vlan')
          end
        end
      end
    end

    context 'with unknown interface name' do
      let(:interface_name) { 'foo0' }

      it 'defaults to ethernet' do
        expect(provider.send(:determine_interface_type)).to eq('ethernet')
      end
    end
  end

  describe '.instances' do
    let(:nmstate_output) do
      {
        'interfaces' => [
          {
            'name' => 'eth0',
            'type' => 'ethernet',
            'state' => 'up',
            'mtu' => 1500,
            'ipv4' => {
              'enabled' => true,
              'dhcp' => false,
              'address' => [
                {
                  'ip' => '192.168.1.100',
                  'prefix-length' => 24
                }
              ]
            },
            'ipv6' => {
              'enabled' => false
            }
          },
          {
            'name' => 'eth1',
            'type' => 'ethernet',
            'state' => 'up',
            'ipv4' => {
              'enabled' => true,
              'dhcp' => true
            },
            'ipv6' => {
              'enabled' => false
            }
          },
          {
            'name' => 'lo',
            'type' => 'loopback',
            'state' => 'up'
          }
        ]
      }.to_json
    end

    before do
      allow(described_class).to receive(:nmstatectl).with('show', '--json').and_return(nmstate_output)
    end

    it 'returns network interfaces excluding loopback' do
      instances = described_class.instances
      expect(instances.length).to eq(2)
      expect(instances.map(&:name)).to contain_exactly('eth0', 'eth1')
    end

    it 'correctly parses static IP configuration' do
      instances = described_class.instances
      eth0 = instances.find { |i| i.name == 'eth0' }

      expect(eth0.get(:method)).to eq(:static)
      expect(eth0.get(:ipaddress)).to eq('192.168.1.100')
      expect(eth0.get(:netmask)).to eq('255.255.255.0')
      expect(eth0.get(:family)).to eq(:inet)
      expect(eth0.get(:mtu)).to eq(1500)
      expect(eth0.get(:onboot)).to eq(:true)
    end

    it 'correctly parses DHCP configuration' do
      instances = described_class.instances
      eth1 = instances.find { |i| i.name == 'eth1' }

      expect(eth1.get(:method)).to eq(:dhcp)
      expect(eth1.get(:family)).to eq(:inet)
      expect(eth1.get(:onboot)).to eq(:true)
    end
  end

  describe '#build_nmstate_config' do
    let(:resource) do
      Puppet::Type.type(:network_config).new(
        name: 'eth0',
        ensure: :present,
        provider: :nm
      )
    end
    let(:provider) { described_class.new(resource) }

    before do
      resource.provider = provider
    end

    context 'with static IPv4 configuration' do
      before do
        resource[:method] = :static
        resource[:family] = :inet
        resource[:ipaddress] = '192.168.1.100'
        resource[:netmask] = '255.255.255.0'
        resource[:mtu] = 1500
        resource[:onboot] = :true
      end

      it 'generates correct nmstate configuration' do
        config = provider.send(:build_nmstate_config)

        expect(config['interfaces']).to be_an(Array)
        expect(config['interfaces'].length).to eq(1)

        interface = config['interfaces'][0]
        expect(interface['name']).to eq('eth0')
        expect(interface['type']).to eq('ethernet')
        expect(interface['state']).to eq('up')
        expect(interface['mtu']).to eq(1500)
        expect(interface['ipv4']['enabled']).to be true
        expect(interface['ipv4']['dhcp']).to be false
        expect(interface['ipv4']['address'][0]['ip']).to eq('192.168.1.100')
        expect(interface['ipv4']['address'][0]['prefix-length']).to eq(24)
        expect(interface['ipv6']['enabled']).to be false
      end
    end

    context 'with DHCP configuration' do
      before do
        resource[:method] = :dhcp
        resource[:family] = :inet
        resource[:onboot] = :true
      end

      it 'generates correct nmstate configuration' do
        config = provider.send(:build_nmstate_config)

        interface = config['interfaces'][0]
        expect(interface['name']).to eq('eth0')
        expect(interface['state']).to eq('up')
        expect(interface['ipv4']['enabled']).to be true
        expect(interface['ipv4']['dhcp']).to be true
        expect(interface['ipv6']['enabled']).to be false
      end
    end

    context 'with IPv6 static configuration' do
      before do
        resource[:method] = :static
        resource[:family] = :inet6
        resource[:ipaddress] = '2001:db8::1'
        resource[:netmask] = '64'
        resource[:onboot] = :true
      end

      it 'generates correct nmstate configuration' do
        config = provider.send(:build_nmstate_config)

        interface = config['interfaces'][0]
        expect(interface['ipv6']['enabled']).to be true
        expect(interface['ipv6']['dhcp']).to be false
        expect(interface['ipv6']['address'][0]['ip']).to eq('2001:db8::1')
        expect(interface['ipv6']['address'][0]['prefix-length']).to eq(64)
        expect(interface['ipv4']['enabled']).to be false
      end
    end

    context 'with manual configuration' do
      before do
        resource[:method] = :manual
        resource[:onboot] = :false
      end

      it 'generates correct nmstate configuration' do
        config = provider.send(:build_nmstate_config)

        interface = config['interfaces'][0]
        expect(interface['state']).to eq('down')
        expect(interface['ipv4']['enabled']).to be false
        expect(interface['ipv6']['enabled']).to be false
      end
    end

    context 'with provider options' do
      before do
        resource[:method] = :static
        resource[:family] = :inet
        resource[:ipaddress] = '192.168.1.100'
        resource[:netmask] = '255.255.255.0'
        resource[:options] = { 'ethernet' => { 'auto-negotiation' => false } }
      end

      it 'includes provider options in configuration' do
        config = provider.send(:build_nmstate_config)

        interface = config['interfaces'][0]
        expect(interface['ethernet']).to eq({ 'auto-negotiation' => false })
      end
    end
  end

  describe '#apply_nmstate_config' do
    let(:resource) do
      Puppet::Type.type(:network_config).new(
        name: 'eth0',
        ensure: :present,
        provider: :nm
      )
    end
    let(:provider) { described_class.new(resource) }
    let(:config) { { 'interfaces' => [{ 'name' => 'eth0' }] } }

    before do
      resource.provider = provider
      allow(provider).to receive(:nmstatectl)
    end

    it 'applies configuration using nmstatectl' do
      expect(Tempfile).to receive(:new).with(['nmstate', '.yaml']).and_call_original
      expect(provider).to receive(:nmstatectl).with('apply', anything)

      provider.send(:apply_nmstate_config, config)
    end
  end

  describe '#destroy' do
    let(:resource) do
      Puppet::Type.type(:network_config).new(
        name: 'eth0',
        ensure: :present,
        provider: :nm
      )
    end
    let(:provider) { described_class.new(resource) }

    before do
      resource.provider = provider
      allow(provider).to receive(:apply_nmstate_config)
    end

    it 'sets interface state to absent' do
      expected_config = {
        'interfaces' => [
          {
            'name' => 'eth0',
            'type' => 'unknown',
            'state' => 'absent'
          }
        ]
      }

      expect(provider).to receive(:apply_nmstate_config).with(expected_config)
      provider.destroy
    end
  end

  describe 'property getters and setters' do
    let(:resource) do
      Puppet::Type.type(:network_config).new(
        name: 'eth0',
        ensure: :present,
        provider: :nm
      )
    end
    let(:provider) { described_class.new(resource) }

    before do
      resource.provider = provider
    end

    describe 'onboot property' do
      it 'gets and sets onboot' do
        provider.onboot = :true
        expect(provider.onboot).to eq(:true)
      end
    end

    describe 'method property' do
      it 'gets and sets method' do
        provider.method = :dhcp
        expect(provider.method).to eq(:dhcp)
      end
    end

    describe 'ipaddress property' do
      it 'gets and sets ipaddress' do
        provider.ipaddress = '192.168.1.100'
        expect(provider.ipaddress).to eq('192.168.1.100')
      end
    end

    describe 'netmask property' do
      it 'gets and sets netmask' do
        provider.netmask = '255.255.255.0'
        expect(provider.netmask).to eq('255.255.255.0')
      end
    end

    describe 'family property' do
      it 'gets and sets family' do
        provider.family = :inet6
        expect(provider.family).to eq(:inet6)
      end
    end

    describe 'mtu property' do
      it 'gets and sets mtu' do
        provider.mtu = 9000
        expect(provider.mtu).to eq(9000)
      end
    end

    describe 'options property' do
      it 'gets and sets options' do
        options = { 'ethernet' => { 'auto-negotiation' => false } }
        provider.options = options
        expect(provider.options).to eq(options)
      end

      it 'defaults to empty hash' do
        expect(provider.options).to eq({})
      end
    end
  end
end
