require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:routes) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_route', 'routes_spec')
    File.read(File.join(basedir, file))
  end

  describe 'when parsing' do
    it 'parses out simple ipv4 iface lines' do
      fixture = fixture_data('simple_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '172.17.67.0/24' }).to eq(
        name: '172.17.67.0/24',
        network: '172.17.67.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'vlan200'
      )
    end

    it 'names default routes "default" and have a 0.0.0.0 netmask' do
      fixture = fixture_data('simple_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == 'default' }).to eq(
        name: 'default',
        network: 'default',
        netmask: '0.0.0.0',
        gateway: '172.18.6.2',
        interface: 'vlan200'
      )
    end

    it 'parses out simple ipv6 iface lines' do
      fixture = fixture_data('simple_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '2a01:4f8:211:9d5:53::/96' }).to eq(
        name: '2a01:4f8:211:9d5:53::/96',
        network: '2a01:4f8:211:9d5:53::',
        netmask: 'ffff:ffff:ffff:ffff:ffff:ffff::',
        gateway: '2a01:4f8:211:9d5::2',
        interface: 'vlan200'
      )
    end

    it 'parses out advanced routes' do
      fixture = fixture_data('advanced_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '172.17.67.0/24' }).to eq(
        name: '172.17.67.0/24',
        network: '172.17.67.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'vlan200',
        options: 'table 200'
      )
    end
    it 'parses out advanced ipv6 iface lines' do
      fixture = fixture_data('advanced_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '2a01:4f8:211:9d5:53::/96' }).to eq(
        name: '2a01:4f8:211:9d5:53::/96',
        network: '2a01:4f8:211:9d5:53::',
        netmask: 'ffff:ffff:ffff:ffff:ffff:ffff::',
        gateway: '2a01:4f8:211:9d5::2',
        interface: 'vlan200',
        options: 'table 200'
      )
    end

    describe 'when reading an invalid routes file' do
      it 'with missing options should fail' do
        expect do
          described_class.parse_file('', "192.168.1.1 255.255.255.0 172.16.0.1\n")
        end.to raise_error(%r{Malformed debian routes file})
      end
    end
  end

  describe 'when formatting' do
    let :route1_provider do
      instance_double(
        'route1_provider',
        name: '172.17.67.0',
        network: '172.17.67.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'vlan200',
        options: 'table 200'
      )
    end

    let :route2_provider do
      instance_double(
        'lo_provider',
        name: '172.28.45.0',
        network: '172.28.45.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'eth0',
        options: 'table 200'
      )
    end

    let :content do
      described_class.format_file('', [route1_provider, route2_provider])
    end

    describe 'writing the route line' do
      it 'writes a single line for the route' do
        expect(content.scan(%r{^172.17.67.0 .*$}).length).to eq(1)
      end
      it 'writes all 6 fields' do
        expect(content.scan(%r{^172.17.67.0 .*$}).first.split(' ').length).to eq(6)
      end

      it 'has the correct fields appended' do
        expect(content.scan(%r{^172.17.67.0 .*$}).first).to include('172.17.67.0 255.255.255.0 172.18.6.2 vlan200 table 200')
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
  describe 'when formatting simple files' do
    let :route1_provider do
      instance_double(
        'route1_provider',
        name: '172.17.67.0',
        network: '172.17.67.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'vlan200',
        options: :absent
      )
    end

    let :route2_provider do
      instance_double(
        'lo_provider',
        name: '172.28.45.0',
        network: '172.28.45.0',
        netmask: '255.255.255.0',
        gateway: '172.18.6.2',
        interface: 'eth0',
        options: :absent
      )
    end

    let :content do
      described_class.format_file('', [route1_provider, route2_provider])
    end

    describe 'writing the route line' do
      it 'writes a single line for the route' do
        expect(content.scan(%r{^172.17.67.0 .*$}).length).to eq(1)
      end

      it 'writes only fields' do
        expect(content.scan(%r{^172.17.67.0 .*$}).first.split(' ').length).to eq(4)
      end

      it 'has the correct fields appended' do
        expect(content.scan(%r{^172.17.67.0 .*$}).first).to include('172.17.67.0 255.255.255.0 172.18.6.2 vlan200')
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
end
