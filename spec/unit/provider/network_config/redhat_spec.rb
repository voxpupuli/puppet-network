#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_config).provider(:redhat) do

    subject { described_class }
  def fixture_data(file)
    basedir = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'redhat_spec')
    File.read(File.join(basedir, file))
  end

  describe 'provider features' do
    it 'should be hotpluggable' do
      described_class.declared_feature?(:hotpluggable).should be_true
    end
  end

  describe "when parsing" do

    describe 'the name' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }
      it { data[:name].should == 'eth0' }
    end

    describe 'the onboot property' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }
      it { data[:name].should be_true }
    end

    describe "the method property" do
      describe 'when dhcp' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-dhcp'))[0] }
        it { data[:method].should == 'dhcp' }
      end

      describe 'when static' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }
        it { data[:method].should == 'static' }
      end
    end

    describe 'the hotplug property' do
      describe 'when true' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-hotplug'))[0] }
        it { data[:hotplug].should == true }
      end

      describe 'when false' do
        let(:data) { described_class.parse_file('eth0', fixture_data('eth0-nohotplug'))[0] }
        it { data[:hotplug].should == false }
      end
    end

    describe 'a static interface' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }
      it { data[:ipaddress].should == '10.0.1.27' }
      it { data[:netmask].should   == '255.255.255.0' }
    end

    describe 'the options property' do
      let(:data) { described_class.parse_file('eth0', fixture_data('eth0-static'))[0] }
      it { data[:options]["USERCTL"].should == 'no' }
      it { data[:options]["NM_CONTROLLED"].should == 'no' }
    end

    describe 'complex configuration' do
      let(:virbonding_path) { File.join(PROJECT_ROOT, 'spec', 'fixtures', 'provider', 'network_config', 'redhat_spec', 'virbonding') }

      before do
        described_class.stubs(:target_files).returns Dir["#{virbonding_path}/*"]
        described_class.any_instance.expects(:select_file).never
      end

      let(:interfaces) { described_class.instances }

      describe 'bond0' do
        subject { described_class.instances.find { |i| i.name == 'bond0' } }
        its(:onboot) { should be_true }
        its(:options) { should == {
            "MTU" => '1500',
            "BONDING_OPTS" => %{mode=4 miimon=100 xmit_hash_policy=layer3+4}
          }
        }
      end

      describe 'bond1' do
        subject { described_class.instances.find { |i| i.name == 'bond1' } }
        its(:onboot) { should be_true }
        its(:ipaddress) { should == '172.20.1.9' }
        its(:netmask) { should == '255.255.255.0' }
        its(:options) { should == {
            "MTU" => '1500',
            "BONDING_OPTS" => %{mode=4 miimon=100 xmit_hash_policy=layer3+4}
          }
        }
      end

      describe 'eth0' do
        subject { described_class.instances.find { |i| i.name == 'eth0' } }
        its(:onboot) { should be_true }
        its(:options) { should == {
            'HWADDR' => '00:12:79:91:28:1f',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond0',
            'MTU'    => '1500',
          }
        }
      end

      describe 'eth1' do
        subject { described_class.instances.find { |i| i.name == 'eth1' } }
        its(:onboot) { should be_true }
        its(:options) { should == {
            'HWADDR' => '00:12:79:91:28:20',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond0',
            'MTU'    => '1500',
          }
        }
      end

      describe 'eth2' do
        subject { described_class.instances.find { |i| i.name == 'eth2' } }
        its(:onboot) { should be_true }
        its(:options) { should == {
            'HWADDR' => '00:26:55:e9:33:c4',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond1',
            'MTU'    => '1500',
          }
        }
      end

      describe 'eth3' do
        subject { described_class.instances.find { |i| i.name == 'eth3' } }
        its(:onboot) { should be_true }
        its(:options) { should == {
            'HWADDR' => '00:26:55:e9:33:c5',
            'SLAVE'  => 'yes',
            'MASTER' => 'bond1',
            'MTU'    => '1500',
          }
        }
      end

      describe 'vlan100' do
        subject { described_class.instances.find { |i| i.name == 'vlan100' } }
        its(:ipaddress) { should == '172.24.61.11' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should == 'static' }
        its(:options)   { should == {
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'VLAN'           => 'yes',
            'PHYSDEV'        => 'bond0',
            'GATEWAY'        => '172.24.61.1',
          }
        }
      end

      describe 'vlan100:0' do
        subject { described_class.instances.find { |i| i.name == 'vlan100:0' } }
        its(:ipaddress) { should == '172.24.61.12' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should == 'static' }
        its(:options)   { should be_nil }
      end

      describe 'vlan200' do
        subject { described_class.instances.find { |i| i.name == 'vlan200' } }
        its(:ipaddress) { should == '172.24.62.1' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should == 'static' }
        its(:options)   { should == {
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'VLAN'           => 'yes',
            'PHYSDEV'        => 'bond0',
          }
        }
      end

      describe 'vlan300' do
        subject { described_class.instances.find { |i| i.name == 'vlan300' } }
        its(:ipaddress) { should == '172.24.63.1' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should be_true }
        its(:options)   { should == {
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'VLAN'           => 'yes',
            'PHYSDEV'        => 'bond0',
          }
        }
      end

      describe 'vlan400' do
        subject { described_class.instances.find { |i| i.name == 'vlan400' } }
        its(:ipaddress) { should == '172.24.64.1' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should be_true }
        its(:options)   { should == {
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'VLAN'           => 'yes',
            'PHYSDEV'        => 'bond0',
          }
        }
      end

      describe 'vlan500' do
        subject { described_class.instances.find { |i| i.name == 'vlan500' } }
        its(:ipaddress) { should == '172.24.65.1' }
        its(:netmask)   { should == '255.255.255.0' }
        its(:onboot)    { should be_false }
        its(:method)    { should be_true }
        its(:options)   { should == {
            'VLAN_NAME_TYPE' => 'VLAN_PLUS_VID_NO_PAD',
            'VLAN'           => 'yes',
            'PHYSDEV'        => 'bond0',
          }
        }
      end
    end

    describe "when reading an invalid interfaces" do
      it "with a mangled key/value should fail" do
        expect { described_class.parse_file('eth0', 'DEVICE: eth0') }.to raise_error Puppet::Error, /malformed/
      end
    end

  end

  describe "when formatting resources" do
    let(:eth0_provider) do
      stub('eth0_provider',
        :name            => "eth0",
        :ensure          => :present,
        :onboot          => true,
        :hotplug         => true,
        :family          => "inet",
        :method          => "none",
        :ipaddress       => "169.254.0.1",
        :netmask         => "255.255.255.0",
        :options         => { "NM_CONTROLLED" => "no", "USERCTL" => "no"}
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
        :options         => {}
      )
    end

    let(:bond0_provider) do
      stub('bond0_provider',
        :name      => 'bond0',
        :onboot    => true,
        :hotplug   => true,
        :ipaddress => '172.20.1.9',
        :netmask   => '255.255.255.0',
        :method    => 'static',
        :options   => {
          "MTU" => '1500',
          "BONDING_OPTS" => %{mode=4 miimon=100 xmit_hash_policy=layer3+4}
        }

      )
    end

    it 'should fail if multiple interfaces are flushed to one file' do
      expect { described_class.format_file('filepath', [eth0_provider, lo_provider]) }.to raise_error Puppet::DevError, /multiple interfaces/
    end

    describe 'with test interface eth0' do
      let(:data) { described_class.format_file('filepath', [eth0_provider]) }

      it { data.should match /DEVICE=eth0/ }
      it { data.should match /ONBOOT=yes/ }
      it { data.should match /BOOTPROTO=none/ }
      it { data.should match /IPADDR=169\.254\.0\.1/ }
      it { data.should match /NETMASK=255\.255\.255\.0/ }
      it { data.should match /NM_CONTROLLED=no/ }
      it { data.should match /USERCTL=no/ }
    end

    describe 'with test interface bond0' do
      let(:data) { described_class.format_file('filepath', [bond0_provider]) }

      it { data.should match /BONDING_OPTS="mode=4 miimon=100 xmit_hash_policy=layer3\+4"/ }
    end
  end
end
