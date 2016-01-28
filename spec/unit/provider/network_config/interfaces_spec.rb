#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_config).provider(:interfaces) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'interfaces_spec')
    File.read(File.join(basedir, file))
  end

  after :each do
    v_level = $VERBOSE
    $VERBOSE = nil
    Puppet::Type::Network_config::ProviderInterfaces::Instance.reset!
    $VERBOSE = v_level
  end

  describe 'provider features' do
    it 'should be hotpluggable' do
      expect(described_class.declared_feature?(:hotpluggable)).to be true
    end
  end

  describe 'when parsing' do
    it 'should parse out auto interfaces' do
      fixture = fixture_data('loopback')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'lo' }[:onboot]).to be true
    end

    it "should parse out allow-hotplug interfaces as 'hotplug'" do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }[:hotplug]).to be true
    end

    it "should parse out allow-auto interfaces as 'onboot'" do
      fixture = fixture_data('two_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth1' }[:onboot]).to be true
    end

    it 'should parse out iface lines' do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:family  => 'inet',
                                                         :method  => 'dhcp',
                                                         :mode    => :raw,
                                                         :name    => 'eth0',
                                                         :hotplug => true,
                                                         :options => {},)
    end

    it 'should ignore source and source-directory lines' do
      fixture = fixture_data('jessie_source_stanza')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:family  => 'inet',
                                                         :method  => 'dhcp',
                                                         :mode    => :raw,
                                                         :name    => 'eth0',
                                                         :hotplug => true,
                                                         :options => {},)
    end

    it 'should ignore variable whitespace in iface lines (network-#26)' do
      fixture = fixture_data('iface_whitespace')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:family  => 'inet',
                                                         :method  => 'dhcp',
                                                         :mode    => :raw,
                                                         :name    => 'eth0',
                                                         :hotplug => true,
                                                         :options => {},)
    end

    it 'should parse out lines following iface lines' do
      fixture = fixture_data('single_interface_static')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:name      => 'eth0',
                                                         :family    => 'inet',
                                                         :method    => 'static',
                                                         :mode      => :raw,
                                                         :ipaddress => '192.168.0.2',
                                                         :netmask   => '255.255.255.0',
                                                         :onboot    => true,
                                                         :mtu       => '1500',
                                                         :options   => {
                                                           'broadcast' => '192.168.0.255',
                                                           'gateway'   => '192.168.0.1',
                                                         })
    end

    # mapping sections aren't support, and might not ever be supported.
    # it "should parse out mapping lines"
    # it "should parse out lines following mapping lines"

    it 'should allow for multiple options sections' do
      fixture = fixture_data('single_interface_options')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:name      => 'eth0',
                                                         :family    => 'inet',
                                                         :method    => 'dhcp',
                                                         :mode      => :raw,
                                                         :options   => {
                                                           'pre-up' => '/bin/touch /tmp/eth0-up',
                                                           'post-down' => [
                                                             '/bin/touch /tmp/eth0-down1',
                                                             '/bin/touch /tmp/eth0-down2',
                                                           ],
                                                         })
    end

    it 'should parse out vlan iface lines' do
      fixture = fixture_data('two_interfaces_static_vlan')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(:name      => 'eth0',
                                                         :family    => 'inet',
                                                         :method    => 'static',
                                                         :mode      => :raw,
                                                         :ipaddress => '192.168.0.2',
                                                         :netmask   => '255.255.255.0',
                                                         :onboot    => true,
                                                         :mtu       => '1500',
                                                         :options   => {
                                                           'broadcast' => '192.168.0.255',
                                                           'gateway'   => '192.168.0.1',
                                                         })
      expect(data.find { |h| h[:name] == 'eth0.1' }).to eq(:name      => 'eth0.1',
                                                           :family    => 'inet',
                                                           :method    => 'static',
                                                           :ipaddress => '172.16.0.2',
                                                           :netmask   => '255.255.255.0',
                                                           :onboot    => true,
                                                           :mtu       => '1500',
                                                           :mode      => :vlan,
                                                           :options   => {
                                                             'broadcast' => '172.16.0.255',
                                                             'gateway'   => '172.16.0.1',
                                                           })
    end

    describe 'when reading an invalid interfaces' do
      it 'with misplaced options should fail' do
        expect do
          described_class.parse_file('', "address 192.168.1.1\niface eth0 inet static\n")
        end.to raise_error
      end

      it 'with an option without a value should fail' do
        expect do
          described_class.parse_file('', "iface eth0 inet manual\naddress")
        end.to raise_error
      end
    end
  end

  describe 'when formatting' do
    let(:eth0_provider) do
      stub('eth0_provider',
           :name            => 'eth0',
           :ensure          => :present,
           :onboot          => true,
           :hotplug         => true,
           :family          => 'inet',
           :method          => 'static',
           :ipaddress       => '169.254.0.1',
           :netmask         => '255.255.0.0',
           :mtu             => '1500',
           :mode            => nil,
           :options         => nil
      )
    end

    let(:eth0_1_provider) do
      stub('eth0_1_provider',
           :name            => 'eth0.1',
           :ensure          => :present,
           :onboot          => true,
           :hotplug         => true,
           :family          => 'inet',
           :method          => 'static',
           :ipaddress       => '169.254.0.1',
           :netmask         => '255.255.0.0',
           :mtu             => '1500',
           :mode            => :vlan,
           :options         => nil
      )
    end

    let(:eth1_provider) do
      stub('eth1_provider',
           :name            => 'eth1',
           :ensure          => :present,
           :onboot          => false,
           :hotplug         => true,
           :family          => 'inet',
           :method          => 'static',
           :ipaddress       => '169.254.0.1',
           :netmask         => '255.255.0.0',
           :mtu             => '576',
           :mode            => nil,
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
           :name            => 'lo',
           :onboot          => true,
           :hotplug         => false,
           :family          => 'inet',
           :method          => 'loopback',
           :ipaddress       => nil,
           :netmask         => nil,
           :mtu             => '65536',
           :mode            => nil,
           :options         => nil
      )
    end

    before do
      described_class.stubs(:header).returns "# HEADER: stubbed header\n"
    end

    let(:content) { described_class.format_file('', [lo_provider, eth0_provider, eth1_provider]) }

    describe 'writing the auto section' do
      it 'should allow at most one section' do
        expect(content.scan(/^auto .+$/).length).to eq(1)
      end

      it 'should have the correct interfaces appended' do
        expect(content.scan(/^auto .+$/).first).to match('auto eth0 lo')
      end
    end

    describe 'writing only the auto section' do
      let(:content) { described_class.format_file('', [lo_provider]) }

      it 'should skip the allow-hotplug line' do
        expect(content.scan(/^allow-hotplug .*$/).length).to eq(0)
      end
    end

    describe 'writing the allow-hotplug section' do
      it 'should allow at most one section' do
        expect(content.scan(/^allow-hotplug .+$/).length).to eq(1)
      end

      it 'should have the correct interfaces appended' do
        expect(content.scan(/^allow-hotplug .+$/).first).to match('allow-hotplug eth0 eth1')
      end
    end

    describe 'writing only the allow-hotplug section' do
      let(:content) { described_class.format_file('', [eth1_provider]) }

      it 'should skip the auto line' do
        expect(content.scan(/^auto .*$/).length).to eq(0)
      end
    end

    describe 'writing iface blocks' do
      let(:content) { described_class.format_file('', [lo_provider, eth0_provider]) }

      it 'should produce an iface block for each interface' do
        expect(content.scan(/iface eth0 inet static/).length).to eq(1)
      end

      it 'should add all options following the iface block' do
        block = [
          'iface eth0 inet static',
          'address 169.254.0.1',
          'netmask 255.255.0.0',
          'mtu 1500',
        ].join("\n")
        expect(content.split('\n').find { |line| line.match(/iface eth0/) }).to match(block)
      end

      it 'should fail if the family property is not defined' do
        lo_provider.unstub(:family)
        lo_provider.stubs(:family).returns nil
        expect { content }.to raise_exception
      end

      it 'should fail if the method property is not defined' do
        lo_provider.unstub(:method)
        lo_provider.stubs(:method).returns nil
        expect { content }.to raise_exception
      end
    end

    describe 'writing vlan iface blocks' do
      let(:content) { described_class.format_file('', [eth0_1_provider]) }

      it 'should add all options following the iface block' do
        block = [
          'iface eth0.1 inet static',
          'vlan-raw-device eth0',
          'address 169.254.0.1',
          'netmask 255.255.0.0',
          'mtu 1500',
        ].join("\n")
        expect(content.split('\n').find { |line| line.match(/iface eth0/) }).to match(block)
      end
    end

    describe 'writing the options section' do
      let(:content) { described_class.format_file('', [eth1_provider]) }

      describe 'with a string value' do
        it 'should write a single entry' do
          expect(content.scan(/pre-up .*$/).size).to eq(1)
        end

        it 'should write the value as an modified string' do
          expect(content.scan(/^\s*pre-up .*$/).first).to eq('    pre-up /bin/touch /tmp/eth1-up')
        end
      end

      describe 'with an array value' do
        it 'should write an entry per array value' do
          expect(content.scan(/post-down .*$/).size).to eq(2)
        end

        it 'should write the values in order' do
          expect(content.scan(/^\s*post-down .*$/)[0]).to eq('    post-down /bin/touch /tmp/eth1-down1')
          expect(content.scan(/^\s*post-down .*$/)[1]).to eq('    post-down /bin/touch /tmp/eth1-down2')
        end
      end
    end
  end
end
