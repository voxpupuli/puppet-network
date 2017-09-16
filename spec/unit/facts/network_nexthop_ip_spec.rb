require 'spec_helper'

describe 'network_nexthop_ip' do
  before do
    Facter.fact(:kernel).stubs(:value).returns('linux')
  end
  context 'on a Linux host' do
    before do
      Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
    end
    it 'execs ip and determine the next hop' do
      expect(Facter.fact(:network_nexthop_ip).value).to eq('1.2.3.4')
    end
  end
  context 'on an OpenVZ VM' do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('linux')
      Facter.fact(:virtual).stubs(:value).returns('openvz')
      Facter::Util::Resolution.stubs(:exec)
    end
    context 'which has the default route via a veth device' do
      before do
        Facter.fact(:macaddress).stubs(:value).returns(nil)
        Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
      end
      it 'execs ip and determine the next hop' do
        expect(Facter.fact(:network_nexthop_ip).value).to eq('1.2.3.4')
      end
    end
    context 'with only venet interfaces' do
      before do
        Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default dev venet0  scope link')
      end
      it 'does not exist' do
        expect(Facter.fact(:network_nexthop_ip).value).to be_nil
      end
    end
  end
end
