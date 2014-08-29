#!/usr/bin/env rspec
require 'spec_helper'
require 'open-uri'
  describe 'network_nexthop_ip' do
    before do
      Facter.fact(:kernel).stubs(:value).returns('linux')
    end
    context 'on a Linux host' do
      before do 
        Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
      end
      it 'should exec ip and determine the next hop' do
        Facter.fact(:network_nexthop_ip).value.should == '1.2.3.4'
      end
    end
    context 'on an OpenVZ VM' do
      before :each do
        Facter.clear
        Facter.fact(:kernel).stubs(:value).returns('linux')
        Facter.fact(:virtual).stubs(:value).returns('openvz')
        Facter::Util::Resolution.stubs(:exec)
      end
      context 'which has the default route via a veth device' do
        before do
          Facter.fact(:macaddress).stubs(:value).returns(nil)
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
        end
        it 'should exec ip and determine the next hop' do
          Facter.fact(:network_nexthop_ip).value.should == '1.2.3.4'
        end
      end
      context 'with only venet interfaces' do
        before do
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default dev venet0  scope link')
        end
        it 'should not exist' do
          Facter.fact(:network_nexthop_ip).value.should == nil
        end
      end
    end

  end
  describe 'network_primary_interface' do
    before do
      Facter.fact(:kernel).stubs(:value).returns('linux')
      Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
    end
    context 'on a Linux host' do
      before do 
        Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
        Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route get 1.2.3.4').returns('1.2.3.4 dev eth0  src 1.2.3.99\n
    cache  mtu 1500 advmss 1460 hoplimit 64')
      end
      it 'should exec ip and determine the primary interface' do
        Facter.fact(:network_primary_interface).value.should == 'eth0'
      end
    end
    context 'on an OpenVZ VM' do
      before :each do
        Facter.clear
        Facter.fact(:kernel).stubs(:value).returns('linux')
        Facter.fact(:virtual).stubs(:value).returns('openvz')
        Facter::Util::Resolution.stubs(:exec)
      end
      context 'with only venet devices' do
        before do
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default dev venet0  scope link')
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route get 8.8.8.8').returns('8.8.8.8 dev venet0  src 1.2.3.99\n
    cache  mtu 1500 advmss 1460 hoplimit 64')
        end
        it 'should exec ip and determine the primary interface' do
          Facter.fact(:network_primary_interface).value.should == 'venet0'
        end
      end
    end
  end
  describe 'network_primary_ip' do
      before do
        Facter.fact(:kernel).stubs(:value).returns('linux')
      end
    context 'on a Linux host' do
      before do 
        Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default via 1.2.3.4 dev eth0')
        Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route get 1.2.3.4').returns("1.2.3.4 dev eth0  src 1.2.3.99\n
    cache  mtu 1500 advmss 1460 hoplimit 64")
      end
      it 'should exec ip and determine the primary ip address' do
        Facter.fact(:network_primary_ip).value.should == '1.2.3.99'
      end
    end
    context 'on an OpenVZ VM' do
      before :each do
        Facter.clear
        Facter.fact(:kernel).stubs(:value).returns('linux')
        Facter.fact(:virtual).stubs(:value).returns('openvz')
        Facter::Util::Resolution.stubs(:exec)
      end
      context 'with only venet devices' do
        before do
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route show 0/0').returns('default dev venet0  scope link')
          Facter::Util::Resolution.stubs(:exec).with('/sbin/ip route get 8.8.8.8').returns("8.8.8.8 dev venet0  src 1.2.3.99\n
    cache  mtu 1500 advmss 1460 hoplimit 64")
        end
        it 'should exec ip and determine the primary interface' do
          Facter.fact(:network_primary_ip).value.should == '1.2.3.99'
        end
      end
    end
  end
