# = Define: network::bond
#
# Instantiate cross-platform bonded interfaces
#
# == Parameters
#
#
# == Examples
#
#     network::bond { 'bond0':
#       ipaddress => '172.16.1.2',
#       netmask   => '255.255.128.0',
#       ensure    => present,
#       slaves    => ['eth0', 'eth1'],
#     }
#
# == See also
#
# * Linux Ethernet Bonding Driver HOWTO, Section 2 "Bonding Driver Options" http://www.kernel.org/doc/Documentation/networking/bonding.txt
#
define network::bond(
  $slaves,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $onboot    = undef,

  $mode             = "active-backup",
  $miimon           = "100",
  $downdelay        = "200",
  $updelay          = "200",
  $lacp_rate        = "slow",
  $primary          = $slaves[0],
  $primary_reselect = "always",
  $xmit_hash_policy = "layer2",
) {

  require network::bond::setup

  kmod::alias { $name:
    source => 'bonding',
    ensure => $ensure,
  }

  case $osfamily {
    Debian: {
      network::bond::debian { $name:
        slaves    => $slaves,
        ensure    => $ensure,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        method    => $method,
        onboot    => $onboot,

        mode             => $mode,
        miimon           => $miimon,
        downdelay        => $downdelay,
        updelay          => $updelay,
        lacp_rate        => $lacp_rate,
        primary          => $primary,
        primary_reselect => $primary_reselect,
        xmit_hash_policy => $xmit_hash_policy,

        require   => Kmod::Alias[$name],
      }
    }
    RedHat: {
      network::bond::redhat { $name:
        slaves    => $slaves,
        ensure    => $ensure,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        method    => $method,
        onboot    => $onboot,

        mode             => $mode,
        miimon           => $miimon,
        downdelay        => $downdelay,
        updelay          => $updelay,
        lacp_rate        => $lacp_rate,
        primary          => $primary,
        primary_reselect => $primary_reselect,
        xmit_hash_policy => $xmit_hash_policy,

        require   => Kmod::Alias[$name],
      }
    }
    default: {
      fail("network::bond does not support osfamily '${osfamily}'")
    }
  }
}
