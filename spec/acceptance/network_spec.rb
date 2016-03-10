require 'spec_helper_acceptance'

describe 'network' do
  describe 'building various network configurations' do
    it 'should work with no errors' do
      pp = <<-EOS
network_config { 'eth0':
  ensure      => present,
  onboot      => 'yes',
  ipaddress   => undef,
  netmask     => undef,
  method      => 'none',
  mtu         => undef,
  reconfigure => false,
  options     => {
    type   => 'Ethernet',
    slave  => 'yes',
    master => 'bond0',
  }
}
network_config { 'bond0':
  ensure      => present,
  onboot      => 'yes',
  mtu         => 9000,
  ipaddress   => '192.168.0.1',
  netmask     => '255.255.255.0',
  options     => {
    type         => 'Bonding',
    bonding_opts => 'mode=4 miimon=100 xmit_hash_policy=layer3+4',
  }
}
      EOS
      # run twice, test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth0') do
      it { should be_file }
      its(:content) { should match(/^DEVICE=eth0$/) }
      its(:content) { should match(/^TYPE=Ethernet$/) }
      its(:content) { should match(/^ONBOOT=yes$/) }
      its(:content) { should_not match(/^IPADDR=/) }
      its(:content) { should_not match(/^GATEWAY=/) }
      its(:content) { should_not match(/^BROADCAST=/) }
      its(:content) { should_not match(/^NETMASK=/) }
      its(:content) { should_not match(/^MTU=/) }
    end

    describe file('/etc/sysconfig/network-scripts/ifcfg-bond0') do
      its(:content) { should match(/^DEVICE=bond0$/) }
      its(:content) { should match(/^TYPE=Bonding$/) }
      its(:content) { should match(/^ONBOOT=yes$/) }
      its(:content) { should match(/^IPADDR=192\.168\.0\.1$/) }
      its(:content) { should match(/^NETMASK=255\.255\.255\.0$/) }
      its(:content) { should match(/^BONDING_OPTS="mode=4 miimon=100 xmit_hash_policy=layer3\+4"$/) }
      its(:content) { should match(/^MTU=9000$/) }
    end
  end
end
