#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_config) do
  before do
    provider_class = stub 'provider class', :name => "fake", :suitable? => true, :supports_parameter? => true
    provider_class.stubs(:new)

    described_class.stubs(:defaultprovider).returns provider_class
    described_class.stubs(:provider).returns provider_class
  end

  [:hotpluggable, :reconfigurable, :provider_options, :ipv6].each do |feature|
    it "should have the #{feature} feature" do
      described_class.provider_feature(feature).should be_kind_of Puppet::Util::ProviderFeatures::ProviderFeature
    end
  end

  [:ensure, :ipaddress, :ip6address, :netmask, :method, :onboot, :options].each do |property|
    it "should have the #{property} property" do
      described_class.attrtype(property).should == :property
    end
  end

  describe "attribute" do
    describe "name parameter" do
      it "should have the name parameter" do
        described_class.attrtype(:name).should == :param
      end

      it "use the name parameter as the namevar" do
        described_class.key_attributes.should == [:name]
      end
    end

    describe :reconfigure do
      it { described_class.attrtype(:reconfigure).should == :param }

      it 'should require the :reconfigurable parameter' do
        described_class.paramclass(:reconfigure).required_features.should be_include :reconfigurable
      end
    end

    describe "ensure" do
      it "should be an ensurable value" do
        described_class.propertybyname(:ensure).ancestors.should be_include(Puppet::Property::Ensure)
      end
    end

    describe 'hotplug' do
      it "should require the :hotpluggable feature" do
        described_class.propertybyname(:hotplug).required_features.should be_include :hotpluggable
      end
    end

    describe "options" do
      it "should require the :has_options feature" do
        described_class.propertybyname(:options).required_features.should be_include :provider_options
      end
    end
  end

  describe "when validating the attribute value" do

    let(:address4){ '127.0.0.1' }
    let(:address6){ '::1' }

    describe "ipaddress" do

      it "should require that a passed address is a valid IPv4 address" do
        expect {
          described_class.new(:name => 'yay', :ipaddress => address4)
        }.to_not raise_error
      end
      it "should fail when passed an IPv6 address" do
        expect {
          described_class.new(:name => 'yay', :ipaddress => address6)
        }.to raise_error Puppet::Error, /not an IPv4 address/
      end
    it "should fail if a malformed address is used" do
      expect {
        described_class.new(:name => 'yay', :ipaddress => 'This is clearly not an IP address')
      }.to raise_error Puppet::Error, /invalid address/
    end

    end

    describe "ip6address" do
      it "should require that a passed address is a valid IPv6 address" do
        expect {
          described_class.new(:name => 'yay', :ip6address => address6)
        }.to_not raise_error
      end
      it "should fail when passed an IPv4 address" do
        expect {
          described_class.new(:name => 'yay', :ip6address => address4)
        }.to raise_error Puppet::Error, /not an IPv6 address/
      end
    end

    describe "netmask" do
      it "should validate a CIDR netmask"
      it "should fail if an invalid CIDR netmask is used" do
        expect do
          described_class.new(:name => 'yay', :netmask => 'This is clearly not a netmask')
        end.to raise_error
      end
    end

    describe "method" do
      [:static, :manual, :dhcp].each do |mth|
        it "should consider '#{mth}' a valid configuration method" do
          described_class.new(:name => 'yay', :method => mth)
        end
      end
    end

    describe 'onboot' do
      [true, false].each do |bool|
        it "should accept '#{bool}' for onboot" do
          described_class.new(:name => 'yay', :onboot => bool)
        end
      end
    end

    describe 'reconfigure' do
      [true, false].each do |bool|
        it "should accept '#{bool}' for reconfigure" do
          described_class.new(:name => 'yay', :reconfigure => bool)
        end
      end
    end

    describe "options" do
      it "should accept an empty hash" do
        expect do
          described_class.new(:name => "valid", :options => {})
        end.to_not raise_error
      end

      it "should use an empty hash as the default" do
        expect do
          described_class.new(:name => "valid")
        end.to_not raise_error
      end
      it "should fail if a non-hash is passed" do
        expect do
          described_class.new(:name => "valid", :options => "geese" )
        end.to raise_error
      end
    end
  end
end
