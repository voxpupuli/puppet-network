require 'spec_helper'

describe 'network::bond', :type => :define do
  let(:title) { 'bond0' }

  let(:params) do
    {
      'ensure'           => 'present',
      'method'           => 'static',
      'ipaddress'        => '172.18.1.2',
      'netmask'          => '255.255.128.0',
      'slaves'           => %w(eth0 eth1),
      'options'          => { 'NM_CONTROLLED' => 'yes' },
      'slave_options'    => { 'NM_CONTROLLED' => 'no' },

      'mode'             => 'active-backup',
      'miimon'           => '100',
      'downdelay'        => '200',
      'updelay'          => '200',
      'lacp_rate'        => 'slow',
      'primary'          => 'eth0',
      'primary_reselect' => 'always',
      'xmit_hash_policy' => 'layer2'
    }
  end

  describe 'on platform' do
    describe 'RedHat' do
      let(:facts) do
        {
          :osfamily      => 'RedHat',
          :augeasversion => '1.4.0'
        }
      end

      it "should create 'network::bond::redhat'" do
        should contain_network__bond__redhat('bond0')
      end

      it "should forward all options to 'network::bond::redhat'" do
        should contain_network__bond__redhat('bond0').with(params)
      end
    end

    describe 'Debian' do
      let(:facts) do
        {
          :osfamily      => 'Debian',
          :augeasversion => '1.4.0'
        }
      end

      it "should create 'network::bond::debian'" do
        should contain_network__bond__debian('bond0')
      end

      it "should forward all options to 'network::bond::debian'" do
        should contain_network__bond__debian('bond0').with(params)
      end
    end

    describe 'on an unsupported osfamily' do
      let(:facts) { { :osfamily => 'SparrowOS' } }

      it 'should fail to compile' do
        expect { should compile }.to raise_error(/network::bond does not support osfamily 'SparrowOS'/)
      end
    end
  end

  describe 'configuring the kernel bonding device' do
    let(:facts) do
      {
        :osfamily      => 'Debian',
        :augeasversion => '1.4.0'
      }
    end

    it { should contain_class('network::bond::setup') }

    it 'should add a kernel module alias for the bonded device' do
      should contain_kmod__alias('bond0').with(:source => 'bonding',
                                               :ensure => 'present')
    end
  end
end
