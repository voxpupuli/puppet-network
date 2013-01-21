puppet-network
==============

Manage non-volatile network configuration.

Travis Test status: [![Build Status](https://travis-ci.org/adrienthebo/puppet-network.png?branch=master)](https://travis-ci.org/adrienthebo/puppet-network)

Examples
--------

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

Dependencies
------------

The debian interfaces provider requires the FileMapper mixin, available at https://github.com/adrienthebo/puppet-filemapper

The network_config type requires the Boolean mixin, available at https://github.com/adrienthebo/puppet-boolean

Note: you many also need to update your master's plugins (run on your puppet master):

    puppet agent -t --noop

Or on puppet 2.7/3.x:

    puppet plugin download

- - -

Contact
-------

  * Source code: https://github.com/adrienthebo/puppet-network
  * Issue tracker: https://github.com/adrienthebo/puppet-network/issues

If you have questions or concerns about this module, contact finch on #puppet
on Freenode, or email adrien@puppetlabs.com.
