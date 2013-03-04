require 'spec_helper'

describe 'network::bond::debian', :type => :define do
  let(:title) { 'bond0' }

  describe "with default bonding params" do
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

    ['eth0', 'eth1'].each do |slave|
      it "should add a network_config resource for #{slave}" do
        should contain_network_config(slave).with_ensure('absent')
      end
    end

    it "should add a network_config resource for bond0" do
      should contain_network_config('bond0').with({
        'ensure'         => 'present',
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
          'bond-xmit-hash-policy' => 'layer2',
        },
      })
    end
  end
end
