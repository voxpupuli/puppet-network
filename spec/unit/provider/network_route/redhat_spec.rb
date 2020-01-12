require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:redhat) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_route', 'redhat')
    File.read(File.join(basedir, file))
  end

  describe 'when parsing' do
    describe 'a simple well formed file' do
      let(:data) { described_class.parse_file('', fixture_data('simple_routes')) }

      it 'parses out normal ipv4 network routes' do
        expect(data.find { |h| h[:name] == '172.17.67.0/30' }).to eq(
          name: '172.17.67.0/30',
          network: '172.17.67.0',
          netmask: '255.255.255.252',
          gateway: '172.18.6.2',
          interface: 'vlan200'
        )
      end
      it 'parses out ipv6 network routes' do
        expect(data.find { |h| h[:name] == '2a01:4f8:211:9d5:53::/96' }).to eq(
          name: '2a01:4f8:211:9d5:53::/96',
          network: '2a01:4f8:211:9d5:53::',
          netmask: 'ffff:ffff:ffff:ffff:ffff:ffff::',
          gateway: '2a01:4f8:211:9d5::2',
          interface: 'vlan200'
        )
      end

      it 'parses out default routes' do
        expect(data.find { |h| h[:name] == 'default' }).to eq(
          name: 'default',
          network: 'default',
          netmask: '0.0.0.0',
          gateway: '10.0.0.1',
          interface: 'eth1'
        )
      end
    end

    describe 'an advanced, well formed file' do
      let :data do
        described_class.parse_file('', fixture_data('advanced_routes'))
      end

      it 'parses out normal ipv4 network routes' do
        expect(data.find { |h| h[:name] == '2a01:4f8:211:9d5:53::/96' }).to eq(
          name: '2a01:4f8:211:9d5:53::/96',
          network: '2a01:4f8:211:9d5:53::',
          netmask: 'ffff:ffff:ffff:ffff:ffff:ffff::',
          gateway: '2a01:4f8:211:9d5::2',
          interface: 'vlan200',
          options: 'table 200'
        )
      end

      it 'parses out normal ipv6 network routes' do
        expect(data.find { |h| h[:name] == '172.17.67.0/30' }).to eq(
          name: '172.17.67.0/30',
          network: '172.17.67.0',
          netmask: '255.255.255.252',
          gateway: '172.18.6.2',
          interface: 'vlan200',
          options: 'table 200'
        )
      end
    end

    describe 'an invalid file' do
      it 'fails' do
        expect do
          described_class.parse_file('', "192.168.1.1/30 via\n")
        end.to raise_error(%r{Malformed redhat route file})
      end
    end
  end

  describe 'when formatting' do
    let :route1_provider do
      instance_double(
        'route1_provider',
        name: '172.17.67.0/30',
        network: '172.17.67.0',
        netmask: '30',
        gateway: '172.18.6.2',
        interface: 'vlan200',
        options: 'table 200'
      )
    end

    let :route2_provider do
      instance_double(
        'lo_provider',
        name: '172.28.45.0/30',
        network: '172.28.45.0',
        netmask: '30',
        gateway: '172.18.6.2',
        interface: 'eth0',
        options: 'table 200'
      )
    end

    let :defaultroute_provider do
      instance_double(
        'defaultroute_provider',
        name: 'default',
        network: 'default',
        netmask: '',
        gateway: '10.0.0.1',
        interface: 'eth1',
        options: 'table 200'
      )
    end

    let :nooptions_provider do
      instance_double(
        'nooptions_provider',
        name: 'default',
        network: 'default',
        netmask: '',
        gateway: '10.0.0.1',
        interface: 'eth2',
        options: :absent
      )
    end

    let :content do
      described_class.format_file('', [route1_provider, route2_provider, defaultroute_provider, nooptions_provider])
    end

    describe 'writing the route line' do
      describe 'For standard (non-default) routes' do
        it 'writes a single line for the route' do
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).length).to eq(1)
        end

        it 'writes 7 fields' do
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).first.split(' ').length).to eq(7)
        end

        it 'has the correct fields appended' do
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).first).to include('172.17.67.0/30 via 172.18.6.2 dev vlan200 table 200')
        end

        it 'fails if the netmask property is not defined' do
          allow(route2_provider).to receive(:netmask).and_return(nil)
          expect { content }.to raise_exception(%r{is missing the required parameter 'netmask'})
        end

        it 'fails if the gateway property is not defined' do
          allow(route2_provider).to receive(:gateway).and_return(nil)
          expect { content }.to raise_exception(%r{is missing the required parameter 'gateway'})
        end
      end
    end

    describe 'for default routes' do
      it 'has the correct fields appended' do
        expect(content.scan(%r{^default .*$}).first).to include('default via 10.0.0.1 dev eth1')
      end

      it 'does not contain the word absent when no options are defined' do
        expect(content).not_to match(%r{absent})
      end
    end
  end
end
