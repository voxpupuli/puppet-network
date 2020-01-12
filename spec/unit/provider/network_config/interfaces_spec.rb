require 'spec_helper'

describe Puppet::Type.type(:network_config).provider(:interfaces) do
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'interfaces_spec')
    File.read(File.join(basedir, file))
  end

  after do
    v_level = $VERBOSE
    $VERBOSE = nil
    Instance.reset!
    $VERBOSE = v_level
  end

  describe 'provider features' do
    it 'is hotpluggable' do
      expect(described_class.declared_feature?(:hotpluggable)).to be true
    end
  end

  describe 'when parsing' do
    it 'parses out auto interfaces' do
      fixture = fixture_data('loopback')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'lo' }[:onboot]).to be true
    end

    it "parses out allow-hotplug interfaces as 'hotplug'" do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }[:hotplug]).to be true
    end

    it "parses out allow-auto interfaces as 'onboot'" do
      fixture = fixture_data('two_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth1' }[:onboot]).to be true
    end

    it 'parses out iface lines' do
      fixture = fixture_data('single_interface_dhcp')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(family: 'inet',
                                                         method: 'dhcp',
                                                         mode: :raw,
                                                         name: 'eth0',
                                                         hotplug: true,
                                                         options: {})
    end

    it 'ignores source and source-directory lines' do
      fixture = fixture_data('jessie_source_stanza')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(family: 'inet',
                                                         method: 'dhcp',
                                                         mode: :raw,
                                                         name: 'eth0',
                                                         hotplug: true,
                                                         options: {})
    end

    it 'ignores variable whitespace in iface lines (network-#26)' do
      fixture = fixture_data('iface_whitespace')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(family: 'inet',
                                                         method: 'dhcp',
                                                         mode: :raw,
                                                         name: 'eth0',
                                                         hotplug: true,
                                                         options: {})
    end

    it 'parses out lines following iface lines' do
      fixture = fixture_data('single_interface_static')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(name: 'eth0',
                                                         family: 'inet',
                                                         method: 'static',
                                                         mode: :raw,
                                                         ipaddress: '192.168.0.2',
                                                         netmask: '255.255.255.0',
                                                         onboot: true,
                                                         mtu: '1500',
                                                         options: {
                                                           'broadcast' => '192.168.0.255',
                                                           'gateway'   => '192.168.0.1'
                                                         })
    end

    # mapping sections aren't support, and might not ever be supported.
    # it "should parse out mapping lines"
    # it "should parse out lines following mapping lines"

    it 'allows for multiple options sections' do
      fixture = fixture_data('single_interface_options')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(name: 'eth0',
                                                         family: 'inet',
                                                         method: 'dhcp',
                                                         mode: :raw,
                                                         options: {
                                                           'pre-up' => '/bin/touch /tmp/eth0-up',
                                                           'post-down' => [
                                                             '/bin/touch /tmp/eth0-down1',
                                                             '/bin/touch /tmp/eth0-down2'
                                                           ]
                                                         })
    end

    it 'parses out vlan iface lines' do # rubocop:disable RSpec/MultipleExpectations
      fixture = fixture_data('two_interfaces_static_vlan')
      data = described_class.parse_file('', fixture)
      expect(data.find { |h| h[:name] == 'eth0' }).to eq(name: 'eth0',
                                                         family: 'inet',
                                                         method: 'static',
                                                         mode: :raw,
                                                         ipaddress: '192.168.0.2',
                                                         netmask: '255.255.255.0',
                                                         onboot: true,
                                                         mtu: '1500',
                                                         options: {
                                                           'broadcast' => '192.168.0.255',
                                                           'gateway'   => '192.168.0.1'
                                                         })
      expect(data.find { |h| h[:name] == 'eth0.1' }).to eq(name: 'eth0.1',
                                                           family: 'inet',
                                                           method: 'static',
                                                           ipaddress: '172.16.0.2',
                                                           netmask: '255.255.255.0',
                                                           onboot: true,
                                                           mtu: '1500',
                                                           mode: :vlan,
                                                           options: {
                                                             'broadcast'       => '172.16.0.255',
                                                             'gateway'         => '172.16.0.1',
                                                             'vlan-raw-device' => 'eth0'
                                                           })
    end

    describe 'when reading an invalid interfaces' do
      it 'with misplaced options should fail' do
        expect do
          described_class.parse_file('', "address 192.168.1.1\niface eth0 inet static\n")
        end.to raise_error(%r{Malformed debian interfaces file})
      end

      it 'with an option without a value should fail' do
        expect do
          described_class.parse_file('', "iface eth0 inet manual\naddress")
        end.to raise_error(%r{Malformed debian interfaces file})
      end
    end
  end

  describe 'when formatting' do
    let(:eth0_provider) do
      instance_double('eth0_provider',
                      name: 'eth0',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'static',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.0.0',
                      mtu: '1500',
                      mode: nil,
                      options: nil)
    end

    let(:vlan20_provider) do
      instance_double('vlan20_provider',
                      name: 'vlan20',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'static',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.0.0',
                      mtu: '1500',
                      mode: :vlan,
                      options: {
                        'vlan-raw-device' => 'eth1'
                      })
    end

    let(:vlan10_provider) do
      instance_double('vlan10_provider',
                      name: 'vlan10',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'dhcp',
                      ipaddress: nil,
                      netmask: nil,
                      mtu: nil,
                      mode: :vlan,
                      options: {})
    end

    let(:eth1_4500_provider) do
      instance_double('eth1_4500_provider',
                      name: 'eth1.4500',
                      ensure: :present,
                      onboot: true,
                      hotplug: true,
                      family: 'inet',
                      method: 'dhcp',
                      ipaddress: nil,
                      netmask: nil,
                      mtu: nil,
                      mode: :vlan,
                      options: {})
    end

    let(:eth1_provider) do
      instance_double('eth1_provider',
                      name: 'eth1',
                      ensure: :present,
                      onboot: false,
                      hotplug: true,
                      family: 'inet',
                      method: 'static',
                      ipaddress: '169.254.0.1',
                      netmask: '255.255.0.0',
                      mtu: '576',
                      mode: nil,
                      options: {
                        'pre-up'    => '/bin/touch /tmp/eth1-up',
                        'post-down' => [
                          '/bin/touch /tmp/eth1-down1',
                          '/bin/touch /tmp/eth1-down2'
                        ]
                      })
    end

    let(:lo_provider) do
      instance_double('lo_provider',
                      name: 'lo',
                      onboot: true,
                      hotplug: false,
                      family: 'inet',
                      method: 'loopback',
                      ipaddress: nil,
                      netmask: nil,
                      mtu: '65536',
                      mode: nil,
                      options: nil)
    end

    before do
      allow(described_class).to receive(:header).and_return "# HEADER: stubbed header\n"
    end

    let(:content) { described_class.format_file('', [lo_provider, eth0_provider, eth1_provider]) } # rubocop:disable RSpec/ScatteredLet

    describe 'writing the auto section' do
      it 'allows at most one section' do
        expect(content.scan(%r{^auto .+$}).length).to eq(1)
      end

      it 'has the correct interfaces appended' do
        expect(content.scan(%r{^auto .+$}).first).to match('auto eth0 lo')
      end
    end

    describe 'writing only the auto section' do
      let(:content) { described_class.format_file('', [lo_provider]) }

      it 'skips the allow-hotplug line' do
        expect(content.scan(%r{^allow-hotplug .*$}).length).to eq(0)
      end
    end

    describe 'writing the allow-hotplug section' do
      it 'allows at most one section' do
        expect(content.scan(%r{^allow-hotplug .+$}).length).to eq(1)
      end

      it 'has the correct interfaces appended' do
        expect(content.scan(%r{^allow-hotplug .+$}).first).to match('allow-hotplug eth0 eth1')
      end
    end

    describe 'writing only the allow-hotplug section' do
      let(:content) { described_class.format_file('', [eth1_provider]) }

      it 'skips the auto line' do
        expect(content.scan(%r{^auto .*$}).length).to eq(0)
      end
    end

    describe 'writing iface blocks' do
      let(:content) { described_class.format_file('', [lo_provider, eth0_provider]) }

      it 'produces an iface block for each interface' do
        expect(content.scan(%r{iface eth0 inet static}).length).to eq(1)
      end

      it 'adds all options following the iface block' do
        block = [
          'iface eth0 inet static',
          'address 169.254.0.1',
          'netmask 255.255.0.0',
          'mtu 1500'
        ].join("\n")
        expect(content.split('\n').find { |line| line.match(%r{iface eth0}) }).to match(block)
      end

      it 'fails if the family property is not defined' do
        allow(lo_provider).to receive(:family).and_return(nil)
        expect { content }.to raise_exception(%r{does not have a family})
      end

      it 'fails if the method property is not defined' do
        allow(lo_provider).to receive(:method).and_return(nil)
        expect { content }.to raise_exception(%r{does not have a method})
      end
    end

    describe 'writing vlan iface blocks' do
      let(:content) { described_class.format_file('', [vlan20_provider]) }

      it 'adds all options following the iface block' do
        block = [
          'iface vlan20 inet static',
          'vlan-raw-device eth1',
          'address 169.254.0.1',
          'netmask 255.255.0.0',
          'mtu 1500'
        ].join("\n")
        expect(content.split('\n').find { |line| line.match(%r{iface vlan20}) }).to match(block)
      end
    end

    describe 'writing wrong vlan iface blocks' do
      let(:content) { described_class.format_file('', [eth1_4500_provider]) }

      it 'fails with wrong VLAN ID' do
        expect { content }.to raise_error(Puppet::Error, %r{Interface eth1.4500: missing vlan-raw-device or wrong VLAN ID in the iface name})
      end
    end

    describe 'writing wrong vlanNN iface blocks' do
      let(:content) { described_class.format_file('', [vlan10_provider]) }

      it 'fails with missing vlan-raw-device' do
        expect { content }.to raise_error(Puppet::Error, %r{Interface vlan10: missing vlan-raw-device or wrong VLAN ID in the iface name})
      end
    end

    describe 'writing the options section' do
      let(:content) { described_class.format_file('', [eth1_provider]) }

      describe 'with a string value' do
        it 'writes a single entry' do
          expect(content.scan(%r{pre-up .*$}).size).to eq(1)
        end

        it 'writes the value as an modified string' do
          expect(content.scan(%r{^\s*pre-up .*$}).first).to eq('    pre-up /bin/touch /tmp/eth1-up')
        end
      end

      describe 'with an array value' do
        it 'writes an entry per array value' do
          expect(content.scan(%r{post-down .*$}).size).to eq(2)
        end

        it 'writes the values in order' do # rubocop:disable RSpec/MultipleExpectations
          expect(content.scan(%r{^\s*post-down .*$})[0]).to eq('    post-down /bin/touch /tmp/eth1-down1')
          expect(content.scan(%r{^\s*post-down .*$})[1]).to eq('    post-down /bin/touch /tmp/eth1-down2')
        end
      end
    end
  end
end
