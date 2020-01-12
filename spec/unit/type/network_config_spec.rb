require 'spec_helper'

describe Puppet::Type.type(:network_config) do
  before do
    provider_class = instance_double 'provider class'
    allow(provider_class).to receive(:name).and_return('fake')
    allow(provider_class).to receive(:suitable?).and_return(true)
    allow(provider_class).to receive(:supports_parameter?).and_return(true)
    allow(provider_class).to receive(:new)
    allow(Puppet::Type.type(:network_config)).to receive(:defaultprovider).and_return(provider_class)
    allow(Puppet::Type.type(:network_config)).to receive(:provider).and_return(provider_class)
  end
  describe 'feature' do
    describe 'hotpluggable' do
      it { expect(Puppet::Type.type(:network_config).provider_feature(:hotpluggable)).not_to be_nil }
    end

    describe 'reconfigurable' do
      it { expect(Puppet::Type.type(:network_config).provider_feature(:reconfigurable)).not_to be_nil }
    end

    describe 'provider_options' do
      it { expect(Puppet::Type.type(:network_config).provider_feature(:provider_options)).not_to be_nil }
    end
  end

  describe 'when validating the attribute' do
    describe :name do # rubocop:disable RSpec/DescribeSymbol
      it { expect(Puppet::Type.type(:network_config).attrtype(:name)).to eq(:param) }
    end

    describe :reconfigure do # rubocop:disable RSpec/DescribeSymbol
      it { expect(Puppet::Type.type(:network_config).attrtype(:reconfigure)).to eq(:param) }

      it 'requires the :reconfigurable parameter' do
        expect(Puppet::Type.type(:network_config).paramclass(:reconfigure).required_features).to include(:reconfigurable)
      end
    end

    %i[ensure ipaddress netmask method family onboot mtu mode options].each do |property|
      describe property do
        it { expect(Puppet::Type.type(:network_config).attrtype(property)).to eq(:property) }
      end
    end

    it 'use the name parameter as the namevar' do
      expect(Puppet::Type.type(:network_config).key_attributes).to eq([:name])
    end

    describe 'ensure' do
      it 'is an ensurable value' do
        expect(Puppet::Type.type(:network_config).propertybyname(:ensure).ancestors).to include(Puppet::Property::Ensure)
      end
    end

    describe 'hotplug' do
      it 'requires the :hotpluggable feature' do
        expect(Puppet::Type.type(:network_config).propertybyname(:hotplug).required_features).to include(:hotpluggable)
      end
    end

    describe 'options' do
      it 'requires the :has_options feature' do
        expect(Puppet::Type.type(:network_config).propertybyname(:options).required_features).to include(:provider_options)
      end
      it 'is a descendant of the KeyValue property' do
        pending 'on conversion to specific type'
        expect(Puppet::Type.type(:network_config).propertybyname(:options).ancestors).to include(Puppet::Property::Ensure)
      end
    end
  end

  describe 'when validating the attribute value' do
    describe 'ipaddress' do
      let(:address4) { '127.0.0.1' }
      let(:address6) { '::1' }

      describe 'using the inet family' do
        it 'requires that a passed address is a valid IPv4 address' do
          expect { Puppet::Type.type(:network_config).new(name: 'yay', family: :inet, ipaddress: address4) }.not_to raise_error
        end
        it 'fails when passed an IPv6 address' do
          pending('Not yet implemented')
          expect { Puppet::Type.type(:network_config).new(name: 'yay', family: :inet, ipaddress: address6) }.to raise_error(%r{not a valid ipv4 address})
        end
      end

      describe 'using the inet6 family' do
        it 'requires that a passed address is a valid IPv6 address' do
          expect { Puppet::Type.type(:network_config).new(name: 'yay', family: :inet6, ipaddress: address6) }.not_to raise_error
        end
        it 'fails when passed an IPv4 address' do
          pending('Not yet implemented')
          expect { Puppet::Type.type(:network_config).new(name: 'yay', family: :inet6, ipaddress: address4) }.to raise_error(%r{not a valid ipv6 address})
        end
      end

      it 'fails if a malformed address is used' do
        expect { Puppet::Type.type(:network_config).new(name: 'yay', ipaddress: 'This is clearly not an IP address') }.to raise_error(%r{requires a valid ipaddress})
      end
    end

    describe 'netmask' do
      it 'fails if an invalid CIDR netmask is used' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', netmask: 'This is clearly not a netmask')
        end.to raise_error(%r{requires a valid netmask})
      end
    end

    describe 'method' do
      %i[static manual dhcp].each do |mth|
        it "should consider '#{mth}' a valid configuration method" do
          Puppet::Type.type(:network_config).new(name: 'yay', method: mth)
        end
      end
    end

    describe 'family' do
      %i[inet inet6].each do |family|
        it "should consider '#{family}' a valid address family" do
          Puppet::Type.type(:network_config).new(name: 'yay', family: family)
        end
      end
    end

    describe 'onboot' do
      [true, false].each do |bool|
        it "should accept '#{bool}' for onboot" do
          Puppet::Type.type(:network_config).new(name: 'yay', onboot: bool)
        end
      end
    end

    describe 'reconfigure' do
      [true, false].each do |bool|
        it "should accept '#{bool}' for reconfigure" do
          Puppet::Type.type(:network_config).new(name: 'yay', reconfigure: bool)
        end
      end
    end

    describe 'mtu' do
      it 'validates a tiny mtu size' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: '42')
      end

      it 'validates a tiny mtu size as a number' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: 42)
      end

      it 'validates a normal mtu size' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: '1500')
      end

      it 'validates a normal mtu size as a number' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: 1500)
      end

      it 'validates a large mtu size' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: '16384')
      end

      it 'validates a large mtu size as a number' do
        Puppet::Type.type(:network_config).new(name: 'yay', mtu: 16_384)
      end

      it 'fails if an random string is passed' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: 'This is clearly not a mtu')
        end.to raise_error(%r{must be a positive integer})
      end

      it 'fails on values < 42' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: '41')
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on numeric values < 42' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: 41)
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on zero' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: '0')
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on numeric zero' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: 0)
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on values > 65536' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: '65537')
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on numeric values > 65536' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: 65_537)
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on negative values' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: '-1500')
        end.to raise_error(%r{is not a valid mtu})
      end

      it 'fails on negative numbers' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: -1500)
        end.to raise_error(%r{is not in the valid mtu range})
      end

      it 'fails on non-integer values' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: '1500.1')
        end.to raise_error(%r{must be a positive integer})
      end

      it 'fails on numeric non-integer values' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mtu: 1500.1)
        end.to raise_error(%r{must be a positive integer})
      end
    end

    describe 'mode' do
      %i[raw vlan].each do |value|
        it "should accept '#{value}' for interface mode" do
          Puppet::Type.type(:network_config).new(name: 'yay', mode: value)
        end
      end
      it 'fails on undefined values' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'yay', mode: 'foo')
        end.to raise_error(%r{Invalid value "foo". Valid values are})
      end
      it 'defaults to :raw' do
        expect(Puppet::Type.type(:network_config).new(name: 'yay')[:mode]).to eq(:raw)
      end
    end

    describe 'options' do
      it 'accepts an empty hash' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'valid', options: {})
        end.not_to raise_error
      end

      it 'uses an empty hash as the default' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'valid')
        end.not_to raise_error
      end
      it 'fails if a non-hash is passed' do
        expect do
          Puppet::Type.type(:network_config).new(name: 'valid', options: 'geese')
        end.to raise_error(%r{requires a hash for the 'options' parameter})
      end
    end
  end
end
