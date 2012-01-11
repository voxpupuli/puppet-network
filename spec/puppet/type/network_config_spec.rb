#!/usr/bin/env ruby -S rspec

require 'spec_helper'

type_class = Puppet::Type.type(:network_config)

describe type_class do
  before do
    @class = type_class
    @provider = stub 'provider'
    @resource = stub 'resource', :resource => nil, :provider => @provider
  end

  it "should ensure that the name param is the namevar"
  it "should ensure that the options attribute is a hash"
end
