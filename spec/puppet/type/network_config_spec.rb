#!/usr/bin/env ruby -S rspec

require 'spec_helper'

type_class = Puppet::Type.type(:network_config)

describe type_class do
  before do
    @class = type_class

    @provider_class = stub 'provider class', :name => "fake", :suitable? => true, :supports_parameter? => true
    @provider = stub 'provider', :class => @provider_class
    @provider_class.stubs(:new).returns @provider

    @class.stubs(:defaultprovider).returns @provider_class
    @class.stubs(:provider).returns @provider_class

    @resource = stub 'resource', :resource => nil, :provider => @provider
  end

  it "should ensure that the name param is the namevar" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating the attributes attribute" do
    it "should accept an empty hash" do
      lambda do
        @class.new(:name => "valid", :attributes => {})
      end.should_not raise_error
    end

    it "should use an empty hash as the default" do
      lambda do
        @class.new(:name => "valid")
      end.should_not raise_error
    end
    it "should fail if a non-hash is passed" do
      lambda do
        @class.new(:name => "valid", :attributes => "geese" )
      end.should raise_error
    end
  end
end
