require 'spec_helper'

describe 'network_nexthop_ip' do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('linux')
  end
  context 'on a Linux host' do
    before do
      allow(Facter::Util::Resolution).to receive(:exec).with('ip route show 0/0').and_return('default via 1.2.3.4 dev eth0')
    end
    it 'execs ip and determine the next hop' do
      expect(Facter.fact(:network_nexthop_ip).value).to eq('1.2.3.4')
    end
  end
  context 'on an OpenVZ VM' do
    before do
      Facter.clear
      allow(Facter.fact(:kernel)).to receive(:value).and_return('linux')
      allow(Facter.fact(:virtual)).to receive(:value).and_return('openvz')
      allow(Facter::Util::Resolution).to receive(:exec)
    end
    context 'which has the default route via a veth device' do
      before do
        allow(Facter::Util::Resolution).to receive(:exec).with('ip route show 0/0').and_return('default via 1.2.3.4 dev eth0')
        allow(Facter.fact(:macaddress)).to receive(:value).and_return(nil)
      end
      it 'execs ip and determine the next hop' do
        expect(Facter.fact(:network_nexthop_ip).value).to eq('1.2.3.4')
      end
    end
    context 'with only venet interfaces' do
      before do
        allow(Facter::Util::Resolution).to receive(:exec).with('ip route show 0/0').and_return('default dev venet0  scope link')
      end
      it 'does not exist' do
        expect(Facter.fact(:network_nexthop_ip).value).to be_nil
      end
    end
  end
end
