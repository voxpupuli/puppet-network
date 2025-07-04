require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:nm) do
  let(:provider_class) { described_class }

  describe 'confines' do
    it 'is confined to systems with nmstatectl' do
      expect(provider_class.confine_collection).to include(
        instance_of(Puppet::Provider::Confine::Exists)
      )
    end

    it 'is confined to systems with systemd service provider' do
      expect(provider_class.confine_collection).to include(
        instance_of(Puppet::Provider::Confine::Variable)
      )
    end
  end

  describe '#instances' do
    let(:nmstate_output) do
      {
        'routes' => {
          'running' => [
            {
              'destination' => '0.0.0.0/0',
              'next-hop-address' => '192.168.1.1',
              'next-hop-interface' => 'eth0',
              'metric' => 100
            },
            {
              'destination' => '10.0.0.0/8',
              'next-hop-address' => '192.168.1.254',
              'next-hop-interface' => 'eth0',
              'metric' => 200
            },
            {
              'destination' => '2001:db8::/32',
              'next-hop-address' => '2001:db8::1',
              'next-hop-interface' => 'eth0',
              'metric' => 300
            }
          ]
        }
      }.to_json
    end

    before do
      allow(provider_class).to receive(:nmstatectl).with('show', '--json').and_return(nmstate_output)
    end

    it 'returns route instances' do
      instances = provider_class.instances
      expect(instances).to have(3).items
    end

    it 'creates instance for default route' do
      instances = provider_class.instances
      default_route = instances.find { |i| i.name == 'default' }

      expect(default_route).not_to be_nil
      expect(default_route.network).to eq('default')
      expect(default_route.gateway).to eq('192.168.1.1')
      expect(default_route.interface).to eq('eth0')
      expect(default_route.netmask).to eq('0.0.0.0')
    end

    it 'creates instance for IPv4 network route' do
      instances = provider_class.instances
      network_route = instances.find { |i| i.name == '10.0.0.0/8' }

      expect(network_route).not_to be_nil
      expect(network_route.network).to eq('10.0.0.0')
      expect(network_route.gateway).to eq('192.168.1.254')
      expect(network_route.interface).to eq('eth0')
      expect(network_route.netmask).to eq('255.0.0.0')
    end

    it 'creates instance for IPv6 network route' do
      instances = provider_class.instances
      ipv6_route = instances.find { |i| i.name == '2001:db8::/32' }

      expect(ipv6_route).not_to be_nil
      expect(ipv6_route.network).to eq('2001:db8::')
      expect(ipv6_route.gateway).to eq('2001:db8::1')
      expect(ipv6_route.interface).to eq('eth0')
      expect(ipv6_route.netmask).to eq('32')
    end
  end

  describe '#prefix_to_netmask' do
    it 'converts IPv4 prefix to netmask' do
      expect(provider_class.prefix_to_netmask(24)).to eq('255.255.255.0')
      expect(provider_class.prefix_to_netmask(16)).to eq('255.255.0.0')
      expect(provider_class.prefix_to_netmask(8)).to eq('255.0.0.0')
      expect(provider_class.prefix_to_netmask(30)).to eq('255.255.255.252')
    end
  end

  describe 'provider behavior' do
    let(:resource) do
      Puppet::Type.type(:network_route).new(
        name: '10.0.0.0/24',
        network: '10.0.0.0',
        netmask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'eth0'
      )
    end

    let(:provider) { provider_class.new(resource) }

    describe '#create' do
      it 'applies nmstate configuration' do
        expect(provider).to receive(:apply_nmstate_config).with(
          hash_including(
            'routes' => {
              'config' => [
                {
                  'destination' => '10.0.0.0/24',
                  'next-hop-interface' => 'eth0',
                  'next-hop-address' => '192.168.1.1'
                }
              ]
            }
          )
        )

        provider.create
      end
    end

    describe '#destroy' do
      it 'removes route via nmstate configuration' do
        expect(provider).to receive(:apply_nmstate_config).with(
          hash_including(
            'routes' => {
              'config' => [
                {
                  'destination' => '10.0.0.0/24',
                  'next-hop-interface' => 'eth0',
                  'next-hop-address' => '192.168.1.1',
                  'state' => 'absent'
                }
              ]
            }
          )
        )

        provider.destroy
      end
    end

    describe '#build_destination' do
      context 'with default route' do
        let(:resource) do
          Puppet::Type.type(:network_route).new(
            name: 'default',
            network: 'default',
            netmask: '0.0.0.0',
            gateway: '192.168.1.1',
            interface: 'eth0'
          )
        end

        it 'returns IPv4 default destination' do
          expect(provider.send(:build_destination)).to eq('0.0.0.0/0')
        end
      end

      context 'with IPv6 default route' do
        let(:resource) do
          Puppet::Type.type(:network_route).new(
            name: 'default',
            network: 'default',
            netmask: '0',
            gateway: '2001:db8::1',
            interface: 'eth0'
          )
        end

        it 'returns IPv6 default destination' do
          expect(provider.send(:build_destination)).to eq('::/0')
        end
      end

      context 'with IPv4 network' do
        let(:resource) do
          Puppet::Type.type(:network_route).new(
            name: '10.0.0.0/24',
            network: '10.0.0.0',
            netmask: '255.255.255.0',
            gateway: '192.168.1.1',
            interface: 'eth0'
          )
        end

        it 'returns CIDR notation' do
          expect(provider.send(:build_destination)).to eq('10.0.0.0/24')
        end
      end

      context 'with IPv6 network' do
        let(:resource) do
          Puppet::Type.type(:network_route).new(
            name: '2001:db8::/32',
            network: '2001:db8::',
            netmask: '32',
            gateway: '2001:db8::1',
            interface: 'eth0'
          )
        end

        it 'returns IPv6 CIDR notation' do
          expect(provider.send(:build_destination)).to eq('2001:db8::/32')
        end
      end
    end

    describe '#netmask_to_prefix' do
      it 'converts netmask to prefix length' do
        expect(provider.send(:netmask_to_prefix, '255.255.255.0')).to eq(24)
        expect(provider.send(:netmask_to_prefix, '255.255.0.0')).to eq(16)
        expect(provider.send(:netmask_to_prefix, '255.0.0.0')).to eq(8)
        expect(provider.send(:netmask_to_prefix, '255.255.255.252')).to eq(30)
      end
    end
  end

  describe 'error handling' do
    context 'when nmstatectl fails' do
      before do
        allow(provider_class).to receive(:nmstatectl).and_raise(Puppet::ExecutionFailure, 'Command failed')
      end

      it 'returns empty array and logs debug message' do
        expect(Puppet).to receive(:debug).with(%r{Failed to get nmstate configuration})
        expect(provider_class.instances).to eq([])
      end
    end

    context 'when JSON parsing fails' do
      before do
        allow(provider_class).to receive(:nmstatectl).and_return('invalid json')
      end

      it 'returns empty array and logs debug message' do
        expect(Puppet).to receive(:debug).with(%r{Failed to parse nmstate JSON output})
        expect(provider_class.instances).to eq([])
      end
    end
  end
end
