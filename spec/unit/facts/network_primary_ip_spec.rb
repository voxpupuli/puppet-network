require 'spec_helper'

describe 'network_primary_ip' do
  before do
    Facter.clear
    Facter.fact(:kernel).stubs(:value).returns('linux')
  end
  context 'on a Linux host with Facter 2.x' do
    before do
      Facter.stubs(:version).returns('2.4.6')
      Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default via 1.2.3.4 dev eth0').once
      Facter::Util::Resolution.stubs(:exec).with('ip route get 1.2.3.4').returns("1.2.3.4 dev eth0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64").once
    end
    it 'execs ip and determine the primary ip address' do
      expect(Facter.fact(:network_primary_ip).value).to eq('1.2.3.99')
    end
  end
  context 'on an OpenVZ VM with Facter 2.x' do
    before do
      Facter.clear
      Facter.stubs(:version).returns('2.4.6')
      Facter.fact(:virtual).stubs(:value).returns('openvz')
      Facter::Util::Resolution.stubs(:exec)
    end
    context 'with only venet devices' do
      before do
        Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default dev venet0  scope link')
        Facter::Util::Resolution.stubs(:exec).with('ip route get 8.8.8.8').returns("8.8.8.8 dev venet0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64")
      end
      it 'execs ip and determine the primary ip address' do
        expect(Facter.fact(:network_primary_ip).value).to eq('1.2.3.99')
      end
    end
  end
  context 'on a Linux host with Facter 3.x' do
    before do
      Facter::Util::Resolution.expects(:exec).never
      ip_fact = Facter.fact(:network_primary_ip)
      networking_fact = Facter::Util::Fact.new(:networking)
      networking_fact.expects(:value).returns('ip' => '2.3.4.5')
      Facter.expects(:fact).with(:networking).returns(networking_fact)
      Facter.expects(:fact).with(:network_primary_ip).returns(ip_fact)
    end
    it 'uses the built-in facts to resolve the primary ip address' do
      # (rski) For some reason this doesn't work with ruby 1.9.3
      Facter.stubs(:version).returns('3.0.0')
      expect(Facter.fact(:network_primary_ip).value).to eq('2.3.4.5')
    end
  end
end
