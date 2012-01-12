#!/usr/bin/env ruby -S rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:network_config).provider(:interfaces)

describe provider_class do
  before do
    @provider = provider_class
    @provider.stubs(:filetype).returns(Puppet::Util::FileType::FileTypeRam)
    @provider.stubs(:filetype=)
  end

  describe ".read_interfaces" do
    it "should read the contents of the default interfaces file"
    it "should parse out auto interfaces"
    it "should parse out allow-auto and allow-hotplug interfaces"
    it "should parse out iface lines"
    it "should parse out lines following iface lines"
    it "should parse out mapping lines"
    it "should parse out lines following mapping lines"

    it "should fail when reading a malformed interfaces file"
  end

  describe ".instances" do
    it "should create a provider for each discovered interface"
    it "should copy the interface attributes into the provider attributes"
  end

  describe ".prefetch" do
    it "should match resources to providers whose names match"
  end

  describe "when flushing" do
    it "should add interfaces that do not exist"
    it "should remove interfaces that do exist whose ensure is absent"
    it "should not modify unmanaged interfaces"
    it "should back up the file if changes are made"
    it "should not flush if the interfaces file is malformed"
  end
end
