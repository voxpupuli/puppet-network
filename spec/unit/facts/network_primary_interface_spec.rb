require 'spec_helper'

describe 'network_primary_interface' do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('linux')
  end
  context 'on a Linux host with Facter 2.x' do
    before do
      allow(Facter::Util::Resolution).to receive(:exec).with('ip route show 0/0').and_return('default via 1.2.3.4 dev eth0')
      allow(Facter::Util::Resolution).to receive(:exec).with('ip route get 1.2.3.4').and_return('1.2.3.4 dev eth0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64')
    end
    it 'execs ip and determines the primary interface' do
      expect(Facter.fact(:network_primary_interface).value).to eq('eth0')
    end
  end
  context 'on an OpenVZ VM with Facter 2.x' do
    before do
      allow(Facter).to receive(:version).and_return('2.4.6')
      allow(Facter.fact(:kernel)).to receive(:value).and_return('linux')
      allow(Facter.fact(:virtual)).to receive(:value).and_return('openvz')
      allow(Facter::Util::Resolution).to receive(:exec)
    end
    context 'with only venet devices' do
      before do
        allow(Facter::Util::Resolution).to receive(:exec).with('ip route show 0/0').and_return('default dev venet0  scope link')
        allow(Facter::Util::Resolution).to receive(:exec).with('ip route get 8.8.8.8').and_return('8.8.8.8 dev venet0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64')
      end
      it 'execs ip and determines the primary interface' do
        expect(Facter.fact(:network_primary_interface).value).to eq('venet0')
      end
    end
  end
  context 'on a Linux host with Facter 3' do
    before do
      interface_fact = Facter.fact(:network_primary_interface)
      networking_fact = Facter::Util::Fact.new(:networking)
      allow(networking_fact).to receive(:value).and_return('primary' => 'eth1')
      allow(Facter).to receive(:fact).with(:network_primary_interface).and_return(interface_fact)
      allow(Facter).to receive(:fact).with(:networking).and_return(networking_fact)
      allow(Facter).to receive(:version).and_return('3.0.0')
    end
    it 'uses the built-in facts to determine the primary interface' do
      # (rski) For some reason with ruby 1.9.3 this doesn't work in the before block
      expect(Facter.fact(:network_primary_interface).value).to eq('eth1')
    end
  end
end
