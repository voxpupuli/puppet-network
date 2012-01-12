#!/usr/bin/env ruby -S rspec

require 'spec_helper'

def fixture_data(file)
  basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'interfaces_spec')
  File.read(File.join(basedir, file))
end

provider_class = Puppet::Type.type(:network_config).provider(:interfaces)

describe provider_class do
  before do
    @provider_class = provider_class
  end

  describe ".read_interfaces" do
    before :each do
      @filetype = stub 'filetype'
      @flatfile_class.stubs(:new).returns @filetype
      Puppet::Util::FileType.expects(:filetype).with(:flat).returns @flatfile_class
      @provider_class.initvars
    end

    it "should read the contents of the default interfaces file" do
      @filetype.expects(:read).returns("")
      @provider_class.read_interfaces
    end

    it "should parse out auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('loopback'))
      @provider_class.read_interfaces
      @provider_class.interfaces.keys.sort.should == [:lo]
      @provider_class.interfaces[:lo][:auto].should be_true
    end

    it "should parse out allow-hotplug interfaces" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.read_interfaces
      @provider_class.interfaces[:eth0][:"allow-hotplug"].should be_true
    end

    it "should parse out allow-auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('two_interface_dhcp'))
      @provider_class.read_interfaces
      @provider_class.interfaces[:eth1][:"allow-auto"].should be_true
    end

    it "should parse out iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.read_interfaces
      @provider_class.interfaces[:eth0][:proto].should == "inet"
      @provider_class.interfaces[:eth0][:method].should == "dhcp"
    end

    it "should parse out lines following iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_static'))
      @provider_class.read_interfaces
      @provider_class.interfaces[:eth0][:proto].should == "inet"
      @provider_class.interfaces[:eth0][:method].should == "static"
      @provider_class.interfaces[:eth0][:address].should == "192.168.0.2"
      @provider_class.interfaces[:eth0][:broadcast].should == "192.168.0.255"
      @provider_class.interfaces[:eth0][:netmask].should == "255.255.255.0"
      @provider_class.interfaces[:eth0][:gateway].should == "192.168.0.1"
    end

    it "should parse out mapping lines"
    it "should parse out lines following mapping lines"

    describe "when reading an invalid interfaces" do

      it "with misplaced options should fail" do
        @filetype.expects(:read).returns("address 192.168.1.1\niface eth0 inet static\n")
        lambda do
          @provider_class.read_interfaces
        end.should raise_error
      end

      it "with an option without a value should fail" do
        @filetype.expects(:read).returns("iface eth0 inet manual\naddress")
        lambda do
          @provider_class.read_interfaces
        end.should raise_error
      end
    end
  end

  describe ".instances" do
    before :each do
      @filetype = stub 'filetype'
      @flatfile_class.stubs(:new).returns @filetype
      Puppet::Util::FileType.expects(:filetype).with(:flat).returns @flatfile_class
      @provider_class.initvars
    end

    it "should create a provider for each discovered interface" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      providers = @provider_class.instances
      providers.map {|prov| prov.name}.sort.should == [:eth0, :lo]
    end

    it "should copy the interface attributes into the provider attributes" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      providers = @provider_class.instances
      eth0_provider = providers.select {|prov| prov.name == :eth0}.first
      lo_provider   = providers.select {|prov| prov.name == :lo}.first

      eth0_provider.attributes.should == {:proto => "inet", :method => "dhcp", :"allow-hotplug" => true}
      lo_provider.attributes.should == {:proto => "inet", :method => "loopback", :auto => true}
    end
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
