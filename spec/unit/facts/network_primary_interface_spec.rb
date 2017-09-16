require 'spec_helper'

describe 'network_primary_interface' do
  before do
    Facter.clear
    Facter.fact(:kernel).stubs(:value).returns('linux')
  end
  context 'on a Linux host with Facter 2.x' do
    before do
      Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
      Facter::Util::Resolution.stubs(:exec).with('ip route get 1.2.3.4').returns('1.2.3.4 dev eth0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64')
    end
    it 'execs ip and determines the primary interface' do
      expect(Facter.fact(:network_primary_interface).value).to eq('eth0')
    end
  end
  context 'on an OpenVZ VM with Facter 2.x' do
    before do
      Facter.stubs(:version).returns('2.4.6')
      Facter.fact(:kernel).stubs(:value).returns('linux')
      Facter.fact(:virtual).stubs(:value).returns('openvz')
      Facter::Util::Resolution.stubs(:exec)
    end
    context 'with only venet devices' do
      before do
        Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default dev venet0  scope link')
        Facter::Util::Resolution.stubs(:exec).with('ip route get 8.8.8.8').returns('8.8.8.8 dev venet0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64')
      end
      it 'execs ip and determines the primary interface' do
        expect(Facter.fact(:network_primary_interface).value).to eq('venet0')
      end
    end
  end
  context 'on a Linux host with Facter 3' do
    before do
      Facter::Util::Resolution.expects(:exec).never
      interface_fact = Facter.fact(:network_primary_interface)
      networking_fact = Facter::Util::Fact.new(:networking)
      networking_fact.expects(:value).returns('primary' => 'eth1')
      Facter.expects(:fact).with(:networking).returns(networking_fact)
      Facter.expects(:fact).with(:network_primary_interface).returns(interface_fact)
    end
    it 'uses the built-in facts to determine the primary interface' do
      # (rski) For some reason with ruby 1.9.3 this doesn't work in the before block
      Facter.stubs(:version).returns('3.0.0')
      expect(Facter.fact(:network_primary_interface).value).to eq('eth1')
    end
  end
end
