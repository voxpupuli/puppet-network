#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_config) do
  before do
    provider_class = stub 'provider class', :name => "fake", :suitable? => true, :supports_parameter? => true
    provider_class.stubs(:new)

    described_class.stubs(:defaultprovider).returns provider_class
    described_class.stubs(:provider).returns provider_class
  end

  describe "feature" do

    describe "hotpluggable" do
      it { described_class.provider_feature(:hotpluggable).should_not be_nil }
    end

    describe "reconfigurable" do
      it { described_class.provider_feature(:reconfigurable).should_not be_nil }
    end

    describe "provider_options" do
      it { described_class.provider_feature(:provider_options).should_not be_nil }
    end
  end

  describe "when validating the attribute" do

    describe :name do
      it { described_class.attrtype(:name).should == :param }
    end

    describe :reconfigure do
      it { described_class.attrtype(:reconfigure).should == :param }

      it 'should require the :reconfigurable parameter' do
        described_class.paramclass(:reconfigure).required_features.should be_include :reconfigurable
      end
    end

    [:ensure, :ipaddress, :netmask, :method, :family, :onboot, :options].each do |property|
      describe property do
        it { described_class.attrtype(property).should == :property }
      end
    end

    it "use the name parameter as the namevar" do
      described_class.key_attributes.should == [:name]
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
      it "should be a descendant of the KeyValue property" do
        pending "on conversion to specific type"
        described_class.propertybyname(:options).ancestors.should be_include(Puppet::Property::Ensure)
      end
    end
  end

  describe "when validating the attribute value" do

    describe "ipaddress" do

      let(:address4){ '127.0.0.1' }
      let(:address6){ '::1' }

      describe "using the inet family" do

        it "should require that a passed address is a valid IPv4 address" do
          expect { described_class.new(:name => 'yay', :family => :inet, :ipaddress => address4) }.to_not raise_error
        end
        it "should fail when passed an IPv6 address" do
          pending "implementation of IP address validation"
          expect { described_class.new(:name => 'yay', :family => :inet, :ipaddress => address6) }.to raise_error
        end
      end

      describe "using the inet6 family" do
        it "should require that a passed address is a valid IPv6 address" do
          expect { described_class.new(:name => 'yay', :family => :inet6, :ipaddress => address6) }.to_not raise_error
        end
        it "should fail when passed an IPv4 address" do
          pending "implementation of IP address validation"
          expect { described_class.new(:name => 'yay', :family => :inet6, :ipaddress => address4) }.to raise_error
        end
      end

      it "should fail if a malformed address is used" do
        pending "implementation of IP address validation"
        expect { described_class.new(:name => 'yay', :ipaddress => 'This is clearly not an IP address') }.to raise_error
      end
    end

    describe "netmask" do
      it "should validate a CIDR netmask"
      it "should fail if an invalid CIDR netmask is used" do
        pending "implementation of IP address validation"
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

    describe "family" do
      [:inet, :inet6].each do |family|
        it "should consider '#{family}' a valid address family" do
          described_class.new(:name => 'yay', :family => family)
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
