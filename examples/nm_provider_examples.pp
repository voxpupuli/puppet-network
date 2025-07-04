# Example Puppet manifest demonstrating NetworkManager provider usage
#
# This example shows various network configurations using the NetworkManager
# provider with nmstate backend.

# Basic DHCP configuration
network_config { 'eth0':
  ensure   => present,
  provider => 'nm',
  method   => 'dhcp',
  family   => 'inet',
  onboot   => true,
}

# Static IP configuration with custom MTU
network_config { 'eth1':
  ensure      => present,
  provider    => 'nm',
  method      => 'static',
  family      => 'inet',
  ipaddress   => '192.168.1.100',
  netmask     => '255.255.255.0',
  onboot      => true,
  mtu         => 9000,
  reconfigure => true,
}

# IPv6 static configuration
network_config { 'eth2':
  ensure    => present,
  provider  => 'nm',
  method    => 'static',
  family    => 'inet6',
  ipaddress => '2001:db8::1',
  netmask   => '64',
  onboot    => true,
}

# WiFi interface configuration (requires additional NetworkManager configuration)
network_config { 'wlan0':
  ensure   => present,
  provider => 'nm',
  method   => 'dhcp',
  family   => 'inet',
  onboot   => false,
  hotplug  => true,
}

# Bond interface with advanced options
network_config { 'bond0':
  ensure    => present,
  provider  => 'nm',
  method    => 'static',
  family    => 'inet',
  ipaddress => '10.0.0.100',
  netmask   => '255.255.255.0',
  onboot    => true,
  options   => {
    'link-aggregation' => {
      'mode'    => 'active-backup',
      'options' => {
        'miimon'  => '100',
        'primary' => 'eth0'
      },
      'slaves'  => ['eth0', 'eth1'],
    }
  }
}

# VLAN interface configuration
network_config { 'eth0.100':
  ensure    => present,
  provider  => 'nm',
  method    => 'static',
  family    => 'inet',
  ipaddress => '172.16.100.10',
  netmask   => '255.255.255.0',
  onboot    => true,
  options   => {
    'vlan' => {
      'base-iface' => 'eth0',
      'id'         => 100,
    }
  }
}

# Bridge interface configuration
network_config { 'br0':
  ensure   => present,
  provider => 'nm',
  method   => 'dhcp',
  family   => 'inet',
  onboot   => true,
  options  => {
    'bridge' => {
      'stp' => {
        'enabled' => false,
      }
    }
  }
}

# Interface with custom ethernet settings
network_config { 'eth3':
  ensure    => present,
  provider  => 'nm',
  method    => 'static',
  family    => 'inet',
  ipaddress => '192.168.2.10',
  netmask   => '255.255.255.0',
  onboot    => true,
  options   => {
    'ethernet' => {
      'auto-negotiation' => false,
      'speed'            => 1000,
      'duplex'           => 'full',
    }
  }
}

# Disabled interface
network_config { 'eth4':
  ensure   => present,
  provider => 'nm',
  method   => 'manual',
  onboot   => false,
}
