puppet-network
==============

Manage non-volatile network and route configuration.

Travis Test status: [![Build Status](https://travis-ci.org/puppet-community/puppet-network.png?branch=master)](https://travis-ci.org/puppet-community/puppet-network)

Examples
--------

Interface configuration

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

Route configuration

  For Debian:

    network_route { '172.17.67.0':
      ensure    => 'present',
      gateway   => '172.18.6.2',
      interface => 'vlan200',
      netmask   => '255.255.255.0',
      options   => 'table 200',
    }

  For RedHat Enterprise:

    network_route { '172.17.67.0/24':
      ensure    => 'present',
      gateway   => '10.0.2.2',
      interface => 'eth0',
      netmask   => '255.255.255.0',
      network   => '172.17.67.0'
      options   => 'table 200',
    }
    network_route { 'default':
      ensure    => 'present',
      gateway   => '10.0.2.2',
      interface => 'eth0',
      netmask  	=> '0.0.0.0',
      network   => 'default'
    }
  
GRE tunnel configuration

  node 'server1' inherits default {
    network::gre { 'gre1_example':
      ensure    => 'present',
      ipaddress => '172.16.16.2',
      netmask   => '255.255.255.252',
      method    => 'tunnel',
      family    => 'inet',
      onboot    => 'true',
      dstaddr   => '172.16.16.1',
      local     => '192.168.135.69',
      endpoint  => '192.168.135.170',
      ttl       => '255',
      mode      => 'gre',
    }
  }

  node 'server2' inherits default {
    network::gre { 'gre1_example':
      ensure    => 'present',
      ipaddress => '172.16.16.1',
      netmask   => '255.255.255.252',
      method    => 'tunnel',
      family    => 'inet',
      onboot    => 'true',
      dstaddr   => '172.16.16.2',
      local     => '192.168.135.170',
      endpoint  => '192.168.135.69',
      ttl       => '255',
      mode      => 'gre',
    }
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

    # puppet resource network_route 23.23.42.0 ensure=present netmask=255.255.255.0 interface=eth0 gateway=192.168.1.1
    notice: /Network_route[23.23.42.0]/ensure: created
    network_route { '23.23.42.0':
      ensure    => 'present',
      gateway   => '192.168.1.1',
      interface => 'eth0',
      netmask   => '255.255.255.0',
      options   => 'table 200',
    }

Dependencies
------------

The debian interfaces provider requires the FileMapper mixin, available at https://github.com/adrienthebo/puppet-filemapper
The debian routes provider requires the package [ifupdown-extra](http://packages.debian.org/search?suite=all&section=all&arch=any&searchon=names&keywords=ifupdown-extra)

The network_config type requires the Boolean mixin, available at https://github.com/adrienthebo/puppet-boolean

Note: you many also need to update your master's plugins (run on your puppet master):

    puppet agent -t --noop

Or on puppet 2.7/3.x:

    puppet plugin download

- - -

Contact
-------

  * Source code: https://github.com/puppet-community/puppet-network
  * Issue tracker: https://github.com/puppet-community/puppet-network/issues
