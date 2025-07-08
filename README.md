# Network module for Puppet

[![Build Status](https://github.com/voxpupuli/puppet-network/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-network/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-network/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-network/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/network.svg)](https://forge.puppetlabs.com/puppet/network)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/network.svg)](https://forge.puppetlabs.com/puppet/network)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/network.svg)](https://forge.puppetlabs.com/puppet/network)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/network.svg)](https://forge.puppetlabs.com/puppet/network)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-network)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-network.svg)](LICENSE)

## Overview

Manage non-volatile network and route configuration.

This module supports multiple providers for different network management systems:

- **interfaces** - Debian/Ubuntu style `/etc/network/interfaces` 
- **redhat** - Red Hat Enterprise Linux network scripts in `/etc/sysconfig/network-scripts/`
- **sles** - SUSE Linux Enterprise network scripts in `/etc/sysconfig/network/`
- **nm** - NetworkManager using nmstate (requires `nmstatectl` command)

The NetworkManager provider (`nm`) uses [nmstate](https://nmstate.io/) to provide declarative network configuration through NetworkManager. This provider is ideal for modern Linux distributions that use NetworkManager as their primary network management service.

### NetworkManager (nm) Provider

The NetworkManager provider uses nmstate to apply network configuration changes. It requires:

- NetworkManager service running
- `nmstatectl` command available (from the `nmstate` package)

This provider supports all standard `network_config` properties and includes additional features:

- Automatic interface type detection (ethernet, wifi, bond, bridge, vlan)
- Hot-plugging and reconfiguration support
- Provider-specific options for advanced NetworkManager features
- IPv4 and IPv6 support including static, DHCP, and manual configurations

Example usage with NetworkManager provider:

```puppet
# Force use of NetworkManager provider
network_config { 'eth0':
  ensure    => 'present',
  provider  => 'nm',
  family    => 'inet',
  method    => 'static',
  ipaddress => '192.168.1.100',
  netmask   => '255.255.255.0',
  onboot    => 'true',
  mtu       => 1500,
  options   => {
    'ethernet' => {
      'auto-negotiation' => false,
      'speed' => 1000,
      'duplex' => 'full'
    }
  }
}

# DHCP configuration with NetworkManager
network_config { 'eth1':
  ensure   => 'present',
  provider => 'nm',
  family   => 'inet',
  method   => 'dhcp',
  onboot   => 'true',
}

# IPv6 static configuration
network_config { 'eth2':
  ensure      => 'present',
  provider    => 'nm',
  family      => 'inet6',
  method      => 'static',
  ipaddress   => '2001:db8::1',
  netmask     => '64',
  onboot      => 'true',
  reconfigure => 'true',
}
```

## Usage

Interface configuration

```puppet
network_config { 'eth0':
  ensure  => 'present',
  family  => 'inet',
  method  => 'dhcp',
  onboot  => 'true',
  hotplug => 'true',
  options => {'pre-up' => 'sleep 2'},
}

network_config { 'lo':
  ensure => 'present',
  family => 'inet',
  method => 'loopback',
  onboot => 'true',
}

network_config { 'eth1':
  ensure    => 'present',
  family    => 'inet',
  ipaddress => '169.254.0.1',
  method    => 'static',
  netmask   => '255.255.0.0',
  onboot    => 'true',
}
```

Route configuration

Route resources should be named in CIDR notation. If not, they will not be
properly mapped to existing routes and puppet will apply them on every run.
Default routes should be named 'default'.

  For Debian:

```puppet
# default route
network_route { 'default':
  ensure    => 'present',
  network   => 'default',
  netmask   => '0.0.0.0',
  gateway   => '172.18.6.2',
  interface => 'enp3s0f0',
}

# specific route
network_route { '172.17.67.0/24':
  ensure    => 'present',
  gateway   => '172.18.6.2',
  interface => 'vlan200',
  netmask   => '255.255.255.0',
  options   => 'table 200',
}
```

  For RedHat Enterprise:

```puppet
network_route { '172.17.67.0/24':
  ensure    => 'present',
  gateway   => '10.0.2.2',
  interface => 'eth0',
  netmask   => '255.255.255.0',
  network   => '172.17.67.0',
  options   => 'table 200',
}
network_route { 'default':
  ensure    => 'present',
  gateway   => '10.0.2.2',
  interface => 'eth0',
  netmask   => '0.0.0.0',
  network   => 'default'
}
network_route { '10.0.0.2':
  ensure    => 'present',
  network   => 'local',
  interface => 'eth0',
  options   => 'proto 66 scope host table local',
}
```

  For SLES:

```puppet
network_route { 'default':
  ensure    => 'present',
  gateway   => '10.0.2.2',
  interface => 'eth0',
  netmask   => '0.0.0.0',
  network   => 'default'
}
```

Create resources on the fly with the `puppet resource` command:

    root@debian-6:~# puppet resource network_config eth1 ensure=present family=inet method=static ipaddress=169.254.0.1 netmask=255.255.0.0
    notice: /Network_config[eth1]/ensure: created
    network_config { 'eth1':
      ensure    => 'present',
      family    => 'inet',
      ipaddress => '169.254.0.1',
      method    => 'static',
      netmask   => '255.255.0.0',
      onboot    => 'true',
    }

    # puppet resource network_route 23.23.42.0 ensure=present netmask=255.255.255.0 interface=eth0 gateway=192.168.1.1
    notice: /Network_route[23.23.42.0]/ensure: created
    network_route { '23.23.42.0':
      ensure    => 'present',
      gateway   => '192.168.1.1',
      interface => 'eth0',
      netmask   => '255.255.255.0',
      options   => 'table 200',
    }

## Dependencies

This module requires the FileMapper mixin, available at <https://github.com/voxpupuli/puppet-filemapper>.
The network_config type requires the Boolean mixin, available at <https://github.com/adrienthebo/puppet-boolean>.

### NetworkManager Provider Dependencies

The NetworkManager (`nm`) provider requires:

- NetworkManager service running
- `nmstate` package installed (provides `nmstatectl` command)

On RHEL/CentOS/Fedora:
```bash
dnf install nmstate
# or
yum install nmstate
```

On Debian/Ubuntu:
```bash
apt-get install nmstate
```

### Other Provider Dependencies

The debian routes provider requires the package [ifupdown-extra](http://packages.debian.org/search?suite=all&section=all&arch=any&searchon=names&keywords=ifupdown-extra).
`ifupdown-extra` can be installed automatically using the `network` class.
To use it, include it like so in your manifests:

```puppet
include 'network'
```

This class also provides fine-grained control over which packages to install and
how to install them. The documentation for the parameters exposed can be found
[here](https://github.com/voxpupuli/puppet-network/blob/master/manifests/init.pp).

Bonding on Debian requires the package [ifenslave](https://packages.debian.org/search?suite=all&section=all&arch=any&searchon=names&keywords=ifenslave),
which is installed automatically when a bond is defined. This package was
renamed in Debian 9, and therefore bonding does not work on Debian
versions prior to 9.

Note: you may also need to update your master's plugins (run on your puppet master):

    puppet agent -t --noop

Or on puppet 3.8.7/4.x:

    puppet plugin download

- - -

## Contact

* Source code: <https://github.com/voxpupuli/puppet-network>
* Issue tracker: <https://github.com/voxpupuli/puppet-network/issues>
