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

  describe ".parse_file" do
    it "should read the contents of the default interfaces file" do
      @filetype.expects(:read).returns("")
      @provider_class.parse_file
    end

    it "should parse out auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('loopback'))
      @provider_class.parse_file["lo"][:auto].should be_true
    end

    it "should parse out allow-hotplug interfaces" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.parse_file["eth0"][:"allow-hotplug"].should be_true
    end

    it "should parse out allow-auto interfaces" do
      @filetype.expects(:read).returns(fixture_data('two_interface_dhcp'))
      @provider_class.parse_file["eth1"][:"allow-auto"].should be_true
    end

    it "should parse out iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_dhcp'))
      @provider_class.parse_file["eth0"][:iface].should == {:family => "inet", :method => "dhcp", :options => []}
    end

    it "should parse out lines following iface lines" do
      @filetype.expects(:read).returns(fixture_data('single_interface_static'))
      @provider_class.parse_file["eth0"][:iface].should == {
        :family     => "inet",
        :method    => "static",
        :options   => [
          "address 192.168.0.2",
          "broadcast 192.168.0.255",
          "netmask 255.255.255.0",
          "gateway 192.168.0.1",
        ]
      }
    end

    it "should parse out mapping lines"
    it "should parse out lines following mapping lines"

    describe "when reading an invalid interfaces" do

      it "with misplaced options should fail" do
        @filetype.expects(:read).returns("address 192.168.1.1\niface eth0 inet static\n")
        lambda do
          @provider_class.parse_file
        end.should raise_error
      end

      it "with an option without a value should fail" do
        @filetype.expects(:read).returns("iface eth0 inet manual\naddress")
        lambda do
          @provider_class.parse_file
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

      eth0_provider.attributes.should == {
        :iface => {
          :family => "inet",
          :method => "dhcp",
          :options => []
        },
        :"allow-hotplug" => true
      }
      lo_provider.attributes.should == {
        :iface => {
          :family => "inet",
          :method => "loopback",
          :options => []
        },
        :auto => true
      }
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

    it "should create a new absent provider for resources not on disk"
  end

  describe ".format_resources" do
    before :each do
      @eth0_provider = stub 'eth0_provider', :name => "eth0", :ensure => :present, :attributes => {
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :family   => "inet",
          :method  => "static",
          :options => [
            "address 169.254.0.1",
            "netmask 255.255.0.0"
          ]
        },
      }

      @lo_provider = stub 'lo_provider', :name => "lo", :ensure => :present, :attributes => {
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :family   => "inet",
          :method  => "loopback",
        },
      }
    end

    %w{auto allow-auto allow-hotplug}.each do |attr|
      it "should allow at most one #{attr} section" do
        content = @provider_class.format_resources([@lo_provider, @eth0_provider])

        content.select {|line| line.match(/^#{attr} /)}.length.should == 1
        content.find {|line| line.match(/^#{attr} /)}.should == "#{attr} eth0 lo"
      end
    end

    it "should produce an iface block for each interface" do
      content = @provider_class.format_resources([@lo_provider, @eth0_provider])

      content.select {|line| line.match(/iface eth0 inet static/)}.length.should == 1
    end

    it "should add all options following the iface block" do
      content = @provider_class.format_resources([@lo_provider, @eth0_provider])

      block = [
        "iface eth0 inet static",
        "address 169.254.0.1",
        "netmask 255.255.0.0",
      ].join("\n")

      content.find {|line| line.match(/iface eth0/)}.should == block
    end

    it "should fail if the ifaces attribute does not have the family attribute" do
      @lo_provider.unstub(:attributes)
      @lo_provider.stubs(:attributes).returns({
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :method  => "loopback",
        },
      })

      lambda do
        content = @provider_class.format_resources([@lo_provider, @eth0_provider])
      end.should raise_exception
    end

    it "should fail if the ifaces attribute does not have the method attribute" do
      @lo_provider.unstub(:attributes)
      @lo_provider.stubs(:attributes).returns({
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :family => "inet",
        },
      })

      lambda do
        content = @provider_class.format_resources([@lo_provider, @eth0_provider])
      end.should raise_exception
    end
  end

  describe ".flush" do
    before :each do
      @eth0_attributes = {
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :family   => "inet",
          :method  => "static",
          :options => [
            "address 169.254.0.1",
            "netmask 255.255.0.0"
          ]
        },
      }

      @eth1_attributes = {
        :auto            => true,
        :"allow-auto"    => true,
        :"allow-hotplug" => true,
        :iface => {
          :family   => "inet",
          :method  => "dhcp",
        },
      }

      @filetype.stubs(:backup)
      @filetype.stubs(:write)
    end

    it "should add interfaces that do not exist" do
      eth0 = @provider_class.new
      eth0.attributes = @eth0_attributes
      eth0.expects(:ensure).returns :present

      @provider_class.expects(:format_resources).with([eth0]).returns ["yep"]
      @provider_class.flush
    end

    it "should remove interfaces that do exist whose ensure is absent" do
      eth1 = @provider_class.new
      eth1.attributes = @eth1_attributes
      eth1.expects(:ensure).returns :absent

      @provider_class.expects(:format_resources).with([]).returns ["yep"]
      @provider_class.flush
    end

    it "should flush interfaces that were modified"
    it "should not modify unmanaged interfaces"
    it "should back up the file if changes are made"
    it "should not flush if the interfaces file is malformed"
  end
end
