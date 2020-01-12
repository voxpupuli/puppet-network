require 'spec_helper'

describe 'network::bond', type: :define do
  let(:title) { 'bond0' }

  let(:params) do
    {
      'ensure'           => 'present',
      'method'           => 'static',
      'ipaddress'        => '172.18.1.2',
      'netmask'          => '255.255.128.0',
      'slaves'           => %w[eth0 eth1],
      'mtu'              => 1550,
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
          os: { family: 'RedHat' },
          augeasversion: '1.4.0'
        }
      end

      it "creates 'network::bond::redhat'" do
        is_expected.to contain_network__bond__redhat('bond0')
      end

      it "forwards all options to 'network::bond::redhat'" do
        is_expected.to contain_network__bond__redhat('bond0').with(params)
      end
    end

    describe 'Debian' do
      let(:facts) do
        {
          os: { family: 'Debian' },
          augeasversion: '1.4.0'
        }
      end

      it "creates 'network::bond::debian'" do
        is_expected.to contain_network__bond__debian('bond0')
      end

      it "forwards all options to 'network::bond::debian'" do
        is_expected.to contain_network__bond__debian('bond0').with(params)
      end
    end

    describe 'on an unsupported osfamily' do
      let(:facts) do
        {
          os: { family: 'SparrowOS' }
        }
      end

      it 'fails to compile' do
        is_expected.to compile.and_raise_error(%r{network::bond does not support osfamily 'SparrowOS'})
      end
    end
  end

  describe 'configuring the kernel bonding device' do
    let(:facts) do
      {
        os: { family: 'Debian' },
        augeasversion: '1.4.0'
      }
    end

    it { is_expected.to contain_class('network::bond::setup') }

    it 'adds a kernel module alias for the bonded device' do
      is_expected.to contain_kmod__alias('bond0').with(source: 'bonding',
                                                       ensure: 'present')
    end
  end
end
