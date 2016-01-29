#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:redhat) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_route', 'redhat')
    File.read(File.join(basedir, file))
  end

  describe 'when parsing' do
    describe 'a simple well formed file' do
      let(:data) { described_class.parse_file('', fixture_data('simple_routes')) }

      it 'should parse out normal network routes' do
        expect(data.find { |h| h[:name] == '172.17.67.0/30' }).to eq(:name       => '172.17.67.0/30',
                                                                     :network    => '172.17.67.0',
                                                                     :netmask    => '255.255.255.252',
                                                                     :gateway    => '172.18.6.2',
                                                                     :interface  => 'vlan200')
      end

      it 'should parse out default routes' do
        expect(data.find { |h| h[:name] == 'default' }).to eq(:name       => 'default',
                                                              :network    => 'default',
                                                              :netmask    => '0.0.0.0',
                                                              :gateway    => '10.0.0.1',
                                                              :interface  => 'eth1')
      end
    end

    describe 'an advanced, well formed file' do
      let(:data) { described_class.parse_file('', fixture_data('advanced_routes')) }

      it 'should parse out normal network routes' do
        expect(data.find { |h| h[:name] == '172.17.67.0/30' }).to eq(:name       => '172.17.67.0/30',
                                                                     :network    => '172.17.67.0',
                                                                     :netmask    => '255.255.255.252',
                                                                     :gateway    => '172.18.6.2',
                                                                     :interface  => 'vlan200',
                                                                     :options    => 'table 200')
      end
    end

    describe 'an invalid file' do
      it 'should fail' do
        expect do
          described_class.parse_file('', "192.168.1.1/30 via\n")
        end.to raise_error
      end
    end
  end

  describe 'when formatting' do
    let(:route1_provider) do
      stub('route1_provider',
           :name       => '172.17.67.0/30',
           :network    => '172.17.67.0',
           :netmask    => '30',
           :gateway    => '172.18.6.2',
           :interface  => 'vlan200',
           :options    => 'table 200'
      )
    end

    let(:route2_provider) do
      stub('lo_provider',
           :name       => '172.28.45.0/30',
           :network    => '172.28.45.0',
           :netmask    => '30',
           :gateway    => '172.18.6.2',
           :interface  => 'eth0',
           :options    => 'table 200'
      )
    end

    let(:defaultroute_provider) do
      stub('defaultroute_provider',
           :name       => 'default',
           :network    => 'default',
           :netmask    => '',
           :gateway    => '10.0.0.1',
           :interface  => 'eth1',
           :options    => 'table 200'
      )
    end

    let(:content) { described_class.format_file('', [route1_provider, route2_provider, defaultroute_provider]) }

    describe 'writing the route line' do
      describe 'For standard (non-default) routes' do
        it 'should write 5 fields' do
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).length).to eq(1)
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).first.split(' ', 5).length).to eq(5)
        end

        it 'should have the correct fields appended' do
          expect(content.scan(%r{^172.17.67.0\/30 .*$}).first).to include('172.17.67.0/30 via 172.18.6.2 dev vlan200 table 200')
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

    describe 'for default routes' do
      it 'should have the correct fields appended' do
        expect(content.scan(/^default .*$/).first).to include('default via 10.0.0.1 dev eth1')
      end
    end
  end
end
