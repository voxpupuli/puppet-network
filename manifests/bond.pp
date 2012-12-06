# = Define: network::bond
#
# Instantiate cross-platform bonded interfaces
#
# == Parameters
#
#
# == Examples
#
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
  $family    = undef,
  $onboot    = undef,
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
        family    => $family,
        onboot    => $onboot,
        require   => Kmod::Alias[$name],
      }
    }
    RedHat: {
      network::bond::redhat { $name:
        slaves    => $slaves,
        ensure    => $ensure,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        family    => $family,
        onboot    => $onboot,
        require   => Kmod::Alias[$name],
      }
    }
  }
}
