require 'spec_helper'

describe Puppet::Type.type(:network_route) do
  before do
    provider_class = instance_double 'provider class'
    allow(provider_class).to receive(:name).and_return('fake')
    allow(provider_class).to receive(:suitable?).and_return(true)
    allow(provider_class).to receive(:supports_parameter?).and_return(true)
    allow(provider_class).to receive(:new)
    allow(Puppet::Type.type(:network_route)).to receive(:defaultprovider).and_return(provider_class)
    allow(Puppet::Type.type(:network_route)).to receive(:provider).and_return(provider_class)
  end
  describe 'when validating the attribute' do
    describe :name do # rubocop:disable RSpec/DescribeSymbol
      it { expect(Puppet::Type.type(:network_route).attrtype(:name)).to eq(:param) }
    end

    %i[ensure network netmask gateway interface options].each do |property|
      describe property do
        it { expect(Puppet::Type.type(:network_route).attrtype(property)).to eq(:property) }
      end
    end

    it 'use the name parameter as the namevar' do
      expect(Puppet::Type.type(:network_route).key_attributes).to eq([:name])
    end

    describe 'ensure' do
      it 'is an ensurable value' do
        expect(Puppet::Type.type(:network_route).propertybyname(:ensure).ancestors).to be_include(Puppet::Property::Ensure)
      end
    end
  end

  describe 'when validating the attribute value' do
    describe 'network' do
      it 'validates the network as an IP address' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: 'not an ip address', netmask: '255.255.255.0', gateway: '23.23.23.42', interface: 'eth0')
        end.to raise_error(%r{Invalid value for parameter 'network'})
      end
    end

    describe 'netmask' do
      it 'fails if an invalid netmask is used' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: 'This is clearly not a netmask', gateway: '23.23.23.42', interface: 'eth0')
        end.to raise_error(%r{Invalid value for parameter 'netmask'})
      end

      it 'converts netmasks of the CIDR form' do
        r = Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '24', gateway: '23.23.23.42', interface: 'eth0')
        expect(r[:netmask]).to eq('255.255.255.0')
      end

      it 'converts IPv6 netmasks of the CIDR form' do
        r = Puppet::Type.type(:network_route).new(name: 'lxd bridge', network: 'fd58:281b:6eef:eb3d::', netmask: '64', gateway: 'fd58:281b:6eef:eb3d::1', interface: 'lxdbr0')
        expect(r[:netmask]).to eq('ffff:ffff:ffff:ffff::')
      end

      it 'converts netmasks of the expanded netmask form' do
        r = Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '255.255.128.0', gateway: '23.23.23.42', interface: 'eth0')
        expect(r[:netmask]).to eq('255.255.128.0')
      end
    end

    describe 'gateway' do
      it 'validates as an IP address' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '255.255.255.0', gateway: 'not an ip address', interface: 'eth0')
        end.to raise_error(%r{Invalid value for parameter 'gateway'})
      end
    end
  end
end
