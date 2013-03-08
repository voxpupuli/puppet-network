require 'spec_helper'

describe 'network::bond', :type => :define do
  let(:title) { 'bond0' }

  let(:params) do
    {
      'ensure'    => 'present',
      'method'    => 'static',
      'ipaddress' => '172.18.1.2',
      'netmask'   => '255.255.128.0',
      'slaves'    => ['eth0', 'eth1'],

      'mode'             => 'active-backup',
      'miimon'           => '100',
      'downdelay'        => '200',
      'updelay'          => '200',
      'lacp_rate'        => 'slow',
      'primary'          => 'eth0',
      'primary_reselect' => 'always',
      'xmit_hash_policy' => 'layer2',
    }
  end

  describe 'on platform' do
    describe 'RedHat' do
      let(:facts) {{:osfamily => 'RedHat'}}

      it "should create 'network::bond::redhat'" do
        should contain_network__bond__redhat('bond0')
      end

      it "should forward all options to 'network::bond::redhat'" do
        should contain_network__bond__redhat('bond0').with(params)
      end
    end

    describe 'Debian' do
      let(:facts) {{:osfamily => 'Debian'}}

      it "should create 'network::bond::debian'" do
        should contain_network__bond__debian('bond0')
      end

      it "should forward all options to 'network::bond::debian'" do
        should contain_network__bond__debian('bond0').with(params)
      end
    end

    describe 'on an unsupported osfamily' do
      let(:facts) {{:osfamily => 'SparrowOS'}}

      it "should fail to compile" do
        expect { subject }.to raise_error Puppet::Error, /network::bond does not support osfamily 'SparrowOS'/
      end
    end
  end

  describe 'configuring the kernel bonding device' do
    let(:facts) {{:osfamily => 'Debian'}}

    it { should include_class('network::bond::setup') }

    it "should add a kernel module alias for the bonded device" do
      should contain_kmod__alias('bond0').with({
        :source => 'bonding',
        :ensure => 'present',
      })
    end
  end
end
