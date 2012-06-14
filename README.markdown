puppet-network
==============

Manage non-volatile network configuration.

Examples
--------

    network_config { 'eth0':
      ensure  => 'present',
      family  => 'inet',
      method  => 'dhcp',
      onboot  => 'true',
      options => {'allow-hotplug' => 'true', 'pre-up' => 'sleep 2'},
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

**Features**

 * Usable with the `puppet resource` command
 * Single pass prefetching and flushing - only a single read and write is needed

**Limitations**

 * Only the Debian style interfaces provider is implemented
 * It's not perfect?

Dependencies
------------

The debian interfaces provider requires the FileMapper mixin, available at https://github.com/adrienthebo/puppet-filemapper

- - -

Source code: https://github.com/adrienthebo/puppet-network
Issue tracker: https://github.com/adrienthebo/puppet-network/issues
