#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:routes) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_route', 'routes_spec')
    File.read(File.join(basedir, file))
  end

  describe 'when parsing' do
    it 'should parse out simple iface lines' do
      fixture = fixture_data('simple_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '172.17.67.0/24' }).to eq(:name       => '172.17.67.0/24',
                                                                   :network    => '172.17.67.0',
                                                                   :netmask    => '255.255.255.0',
                                                                   :gateway    => '172.18.6.2',
                                                                   :interface  => 'vlan200')
    end

    it 'should parse out advanced routes' do
      fixture = fixture_data('advanced_routes')
      data = described_class.parse_file('', fixture)

      expect(data.find { |h| h[:name] == '172.17.67.0/24' }).to eq(:name       => '172.17.67.0/24',
                                                                   :network    => '172.17.67.0',
                                                                   :netmask    => '255.255.255.0',
                                                                   :gateway    => '172.18.6.2',
                                                                   :interface  => 'vlan200',
                                                                   :options    => 'table 200')
    end

    describe 'when reading an invalid routes file' do
      it 'with missing options should fail' do
        expect do
          described_class.parse_file('', "192.168.1.1 255.255.255.0 172.16.0.1\n")
        end.to raise_error
      end
    end
  end

  describe 'when formatting' do
    let(:route1_provider) do
      stub('route1_provider',
           :name       => '172.17.67.0',
           :network    => '172.17.67.0',
           :netmask    => '255.255.255.0',
           :gateway    => '172.18.6.2',
           :interface  => 'vlan200',
           :options    => 'table 200'
      )
    end

    let(:route2_provider) do
      stub('lo_provider',
           :name       => '172.28.45.0',
           :network    => '172.28.45.0',
           :netmask    => '255.255.255.0',
           :gateway    => '172.18.6.2',
           :interface  => 'eth0',
           :options    => 'table 200'
      )
    end

    let(:content) { described_class.format_file('', [route1_provider, route2_provider]) }

    describe 'writing the route line' do
      it 'should write all 5 fields' do
        expect(content.scan(/^172.17.67.0 .*$/).length).to eq(1)
        expect(content.scan(/^172.17.67.0 .*$/).first.split(/\s/, 5).length).to eq(5)
      end

      it 'should have the correct fields appended' do
        expect(content.scan(/^172.17.67.0 .*$/).first).to include('172.17.67.0 255.255.255.0 172.18.6.2 vlan200 table 200')
      end

      it 'should fail if the netmask property is not defined' do
        route2_provider.unstub(:netmask)
        route2_provider.stubs(:netmask).returns nil
        expect { content }.to raise_exception
      end

      it 'should fail if the gateway property is not defined' do
        route2_provider.unstub(:gateway)
        route2_provider.stubs(:gateway).returns nil
        expect { content }.to raise_exception
      end
    end
  end
end
