#!/usr/bin/env rspec

require 'spec_helper'

describe 'network_primary_ip' do
  before do
    Facter.fact(:kernel).stubs(:value).returns('linux')
  end
  context 'on a Linux host' do
    before do
      Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
      Facter::Util::Resolution.stubs(:exec).with('ip route get 1.2.3.4').returns("1.2.3.4 dev eth0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64")
    end
    it 'execs ip and determine the primary ip address' do
      expect(Facter.fact(:network_primary_ip).value).to eq('1.2.3.99')
    end
  end
  context 'on an OpenVZ VM' do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('linux')
      Facter.fact(:virtual).stubs(:value).returns('openvz')
      Facter::Util::Resolution.stubs(:exec)
    end
    context 'with only venet devices' do
      before do
        Facter::Util::Resolution.stubs(:exec).with('ip route show 0/0').returns('default dev venet0  scope link')
        Facter::Util::Resolution.stubs(:exec).with('ip route get 8.8.8.8').returns("8.8.8.8 dev venet0  src 1.2.3.99\n
  cache  mtu 1500 advmss 1460 hoplimit 64")
      end
      it 'execs ip and determine the primary interface' do
        expect(Facter.fact(:network_primary_ip).value).to eq('1.2.3.99')
      end
    end
  end
end
