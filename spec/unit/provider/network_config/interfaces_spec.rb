#!/usr/bin/env ruby -S rspec

require 'spec_helper'

def fixture_data(file)
  basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'interfaces_spec')
  File.read(File.join(basedir, file))
end

provider_class = Puppet::Type.type(:network_config).provider(:interfaces)

describe provider_class do
  before :each do
    @provider_class = provider_class
    @filetype = stub 'filetype'
    @flatfile_class.stubs(:new).returns @filetype
    Puppet::Util::FileType.expects(:filetype).with(:flat).returns @flatfile_class
    @provider_class.initvars
  end

  describe ".read_interfaces" do
    it "should read the contents of the default interfaces file" do
      @filetype.expects(:read).returns("")
      @provider_class.read_interfaces
    end

    it "should parse out auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('loopback'))
      @provider_class.read_interfaces["lo"][:auto].should be_true
    end

    it "should parse out allow-hotplug interfaces" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.read_interfaces["eth0"][:"allow-hotplug"].should be_true
    end

    it "should parse out allow-auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('two_interface_dhcp'))
      @provider_class.read_interfaces["eth1"][:"allow-auto"].should be_true
    end

    it "should parse out iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.read_interfaces["eth0"][:iface].should == {"proto" => "inet", "method" => "dhcp"}
    end

    it "should parse out lines following iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_static'))
      @provider_class.read_interfaces["eth0"][:iface].should == {
        "proto"     => "inet",
        "method"    => "static",
        "address"   => "192.168.0.2",
        "broadcast" => "192.168.0.255",
        "netmask"   => "255.255.255.0",
        "gateway"   => "192.168.0.1",
      }
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
    it "should create a provider for each discovered interface" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      providers = @provider_class.instances
      providers.map {|prov| prov.name}.sort.should == ["eth0", "lo"]
    end

    it "should copy the interface attributes into the provider attributes" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      providers = @provider_class.instances
      eth0_provider = providers.select {|prov| prov.name == "eth0"}.first
      lo_provider   = providers.select {|prov| prov.name == "lo"}.first

      eth0_provider.attributes.should == {:iface => {"proto" => "inet", "method" => "dhcp"}, :"allow-hotplug" => true}
      lo_provider.attributes.should == {:iface => {"proto" => "inet", "method" => "loopback"}, :auto => true}
    end
  end

  describe ".prefetch" do
    it "should match resources to providers whose names match" do

      @filetype.stubs(:read).returns(fixture_data('single_interface_dhcp'))

      lo_resource   = mock 'lo_resource'
      lo_resource.stubs(:name).returns("lo")
      eth0_resource = mock 'eth0_resource'
      eth0_resource.stubs(:name).returns("eth0")

      lo_provider = stub 'lo_provider', :name => "lo"
      eth0_provider = stub 'eth0_provider', :name => "eth0"

      @provider_class.stubs(:instances).returns [lo_provider, eth0_provider]

      lo_resource.expects(:provider=).with(lo_provider)
      eth0_resource.expects(:provider=).with(eth0_provider)
      lo_resource.expects(:provider).returns(lo_provider)
      eth0_resource.stubs(:provider).returns(eth0_provider)

      @provider_class.prefetch("eth0" => eth0_resource, "lo" => lo_resource)
    end
  end

  describe ".flush" do
    before :each do
      @eth0 = stub 'eth0', :name => "eth0"
      @eth0.stubs(:[]).with(:name).returns 'eth0'
      @eth0.stubs(:provider=)
      @eth0.stubs(:provider)
    end

    it "should add interfaces that do not exist" do
      @filetype.stubs(:read).returns(fixture_data('loopback'))
      @eth0.stubs(:should).with(:ensure).returns :present

      @filetype.expects(:write).with(fixture_data('flush_lo_eth0_dhcp'))
      @provider_class.prefetch("eth0" => @eth0)
      @provider_class.flush
    end

    it "should remove interfaces that do exist whose ensure is absent"
    it "should not modify unmanaged interfaces"
    it "should back up the file if changes are made"
    it "should not flush if the interfaces file is malformed"
  end
end
