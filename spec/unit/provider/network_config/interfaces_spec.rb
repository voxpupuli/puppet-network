#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_config).provider(:interfaces) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'interfaces_spec')
    File.read(File.join(basedir, file))
  end

  after :each do
    described_class::Instance.reset!
  end

  describe 'provider features' do
    it 'should be hotpluggable' do
      described_class.declared_feature?(:hotpluggable).should be_true
    end
  end

  describe "when parsing" do

    it "should parse out auto interfaces" do
      fixture = fixture_data('loopback')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "lo" }[:onboot].should == true
    end

    it "should parse out allow-hotplug interfaces as 'hotplug'" do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "eth0" }[:hotplug].should be_true
    end

    it "should parse out allow-auto interfaces as 'onboot'" do
      fixture = fixture_data('two_interface_dhcp')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "eth1" }[:onboot].should == true
    end

    it "should parse out iface lines" do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "eth0" }.should == {
        :family  => "inet",
        :method  => "dhcp",
        :name    => "eth0",
        :hotplug => true,
        :options => {},
      }
    end

    it "should ignore variable whitespace in iface lines (network-#26)" do
      fixture = fixture_data('iface_whitespace')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "eth0" }.should == {
        :family  => "inet",
        :method  => "dhcp",
        :name    => "eth0",
        :hotplug => true,
        :options => {},
      }
    end

    it "should parse out lines following iface lines" do
      fixture = fixture_data('single_interface_static')
      data = described_class.parse_file('', fixture)
      data.find { |h| h[:name] == "eth0" }.should == {
        :name      => "eth0",
        :family    => "inet",
        :method    => "static",
        :ipaddress => "192.168.0.2",
        :netmask   => "255.255.255.0",
        :onboot    => true,
        :options   => {
          "broadcast" => "192.168.0.255",
          "gateway"   => "192.168.0.1",
        }
      }
    end

    it "should parse out mapping lines"
    it "should parse out lines following mapping lines"

    it "should allow for multiple pre and post up sections"

    describe "when reading an invalid interfaces" do

      it "with misplaced options should fail" do
        expect do
          described_class.parse_file('', "address 192.168.1.1\niface eth0 inet static\n")
        end.to raise_error
      end

      it "with an option without a value should fail" do
        expect do
          described_class.parse_file('', "iface eth0 inet manual\naddress")
        end.to raise_error
      end
    end
  end

  describe "when formatting" do
    let(:eth0_provider) do
      stub('eth0_provider',
        :name            => "eth0",
        :ensure          => :present,
        :onboot          => true,
        :hotplug         => true,
        :family          => "inet",
        :method          => "static",
        :ipaddress       => "169.254.0.1",
        :netmask         => "255.255.0.0",
        :options         => nil
      )
    end

    let(:eth1_provider) do
      stub('eth1_provider',
        :name            => "eth1",
        :ensure          => :present,
        :onboot          => false,
        :hotplug         => true,
        :family          => "inet",
        :method          => "static",
        :ipaddress       => "169.254.0.1",
        :netmask         => "255.255.0.0",
        :options         => {
          'pre-up'    => '/bin/touch /tmp/eth1-up',
          'post-down' => [
            '/bin/touch /tmp/eth1-down1',
            '/bin/touch /tmp/eth1-down2',
          ],
        }
      )
    end

    let(:lo_provider) do
      stub('lo_provider',
        :name            => "lo",
        :onboot          => true,
        :hotplug         => true,
        :family          => "inet",
        :method          => "loopback",
        :ipaddress       => nil,
        :netmask         => nil,
        :options         => nil
      )
    end

    before do
      described_class.stubs(:header).returns "# HEADER: stubbed header\n"
    end

    let(:content) { described_class.format_file('', [lo_provider, eth0_provider, eth1_provider]) }

    describe "writing the auto section" do
      it "should allow at most one section" do
        content.scan(/^auto .*$/).length.should == 1
      end

      it "should have the correct interfaces appended" do
        content.scan(/^auto .*$/).first.should match("auto eth0 lo")
      end
    end

    describe "writing the allow-hotplug section" do
      it "should allow at most one section" do
        content.scan(/^allow-hotplug .*$/).length.should == 1
      end

      it "should have the correct interfaces appended" do
        content.scan(/^allow-hotplug .*$/).first.should match("allow-hotplug eth0 eth1 lo")
      end
    end

    describe "writing iface blocks" do
      let(:content) { described_class.format_file('', [lo_provider, eth0_provider]) }

      it "should produce an iface block for each interface" do
        content.scan(/iface eth0 inet static/).length.should == 1
      end

      it "should add all options following the iface block" do
        block = [
          "iface eth0 inet static",
          "address 169.254.0.1",
          "netmask 255.255.0.0",
        ].join("\n")
        content.split('\n').find {|line| line.match(/iface eth0/)}.should match(block)
      end

      it "should fail if the family property is not defined" do
        lo_provider.unstub(:family)
        lo_provider.stubs(:family).returns nil
        expect { content }.to raise_exception
      end

      it "should fail if the method property is not defined" do
        lo_provider.unstub(:method)
        lo_provider.stubs(:method).returns nil
        expect { content }.to raise_exception
      end
    end

    describe "writing the options section" do
      let(:content) { described_class.format_file('', [eth1_provider]) }

      describe "with a string value" do

        it "should write a single entry" do
          content.scan(/pre-up .*$/).size.should == 1
        end

        it "should write the value as an modified string" do
          content.scan(/^pre-up .*$/).first.should == "pre-up /bin/touch /tmp/eth1-up"
        end
      end

      describe "with an array value" do
        it "should write an entry per array value" do
          content.scan(/post-down .*$/).size.should == 2
        end

        it "should write the values in order" do
          content.scan(/^post-down .*$/)[0].should == "post-down /bin/touch /tmp/eth1-down1"
          content.scan(/^post-down .*$/)[1].should == "post-down /bin/touch /tmp/eth1-down2"
        end
      end
    end
  end
end
