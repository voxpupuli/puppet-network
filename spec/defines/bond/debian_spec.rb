require 'spec_helper'

describe 'network::bond::debian', type: :define do
  let(:title) { 'bond0' }

  describe 'with default bonding params' do
    let(:params) do
      {
        'ensure'    => 'present',
        'method'    => 'static',
        'ipaddress' => '172.18.1.2',
        'netmask'   => '255.255.128.0',
        'slaves'    => %w[eth0 eth1],

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

    %w[eth0 eth1].each do |slave|
      it "should add a network_config resource for #{slave}" do
        is_expected.to contain_network_config(slave).with_ensure('absent')
      end
    end

    it 'adds a network_config resource for bond0' do
      is_expected.to contain_network_config('bond0').with('ensure'         => 'present',
                                                          'method'         => 'static',
                                                          'ipaddress'      => '172.18.1.2',
                                                          'netmask'        => '255.255.128.0',
                                                          'options'        => {
                                                            'bond-slaves'           => 'eth0 eth1',
                                                            'bond-mode'             => 'active-backup',
                                                            'bond-miimon'           => '100',
                                                            'bond-downdelay'        => '200',
                                                            'bond-updelay'          => '200',
                                                            'bond-lacp-rate'        => 'slow',
                                                            'bond-primary'          => 'eth0',
                                                            'bond-primary-reselect' => 'always',
                                                            'bond-xmit-hash-policy' => 'layer2'
                                                          })
    end
  end

  describe 'with non-default bonding params' do
    let(:params) do
      {
        'ensure'           => 'present',
        'method'           => 'static',
        'ipaddress'        => '10.20.2.1',
        'netmask'          => '255.255.255.192',
        'slaves'           => %w[eth0 eth1 eth2],
        'mtu'              => 1550,
        'options'          => { 'bond-future-option' => 'yes' },
        'slave_options'    => { 'slave-future-option' => 'no' },
        'hotplug'          => 'false',

        'mode'             => 'balance-rr',
        'miimon'           => '50',
        'downdelay'        => '100',
        'updelay'          => '100',
        'lacp_rate'        => 'fast',
        'xmit_hash_policy' => 'layer3+4'
      }
    end

    %w[eth0 eth1 eth2].each do |slave|
      it "should add a network_config resource for #{slave}" do
        is_expected.to contain_network_config(slave).with_ensure('absent')
      end
    end

    it 'adds a network_config resource for bond0' do
      is_expected.to contain_network_config('bond0').with('ensure'         => 'present',
                                                          'method'         => 'static',
                                                          'ipaddress'      => '10.20.2.1',
                                                          'netmask'        => '255.255.255.192',
                                                          'hotplug'        => false,
                                                          'options'        => {
                                                            'bond-slaves'           => 'eth0 eth1 eth2',
                                                            'bond-mode'             => 'balance-rr',
                                                            'bond-miimon'           => '50',
                                                            'bond-downdelay'        => '100',
                                                            'bond-updelay'          => '100',
                                                            'bond-lacp-rate'        => 'fast',
                                                            'bond-xmit-hash-policy' => 'layer3+4',
                                                            'bond-future-option'    => 'yes',
                                                            'post-up'               => 'ip link set dev bond0 mtu 1550'
                                                          })
    end
  end
end
