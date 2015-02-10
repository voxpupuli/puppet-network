# = Define: network::gre
#
# Instantiate cross-platform gre tunnels
#
# == Parameters
#
# === interface parameters
#
# [*ensure*]
#
# The ensure value for the gre interface.
#
# Default: present
#
# [*ipaddress*]
#
# The IPv4 address of the gre interface.
#
# [*netmask*]
#
# The IPv4 network mask of the gre interface.
#
# [*method*]
#
# The network configuration method.
#
# Default: tunnel
#
# [*onboot*]
#
# Whether to bring the interface up on boot.
#
# === GRE parameters
#
# [*local*]
#
# The IP address of local interface the tunnel will apply to
#
# [*dstaddr*]
#
# The IP address for remote GRE tunnel host
#
# [*endpoint*]
#
# IP address of remote host the tunnel will terminate at
#
# [*ttl*]
#
# The "Time to Live" value for the tunnel (seconds)
#
# Default: 255
#
# [*mode*]
#
# Default: 'gre'
#
# == Examples
#
# Server1 example GRE to Server2
#    network::gre { 'gre1_example':
#      ensure    => 'present',
#      ipaddress => '172.16.16.2',
#      netmask   => '255.255.255.252',
#      method    => 'tunnel',
#      family    => 'inet',
#      onboot    => 'true',
#      dstaddr   => '172.16.16.1',
#      local     => '192.168.135.69',
#      endpoint  => '192.168.135.170',
#      ttl       => '255',
#      mode      => 'gre',
#    }
#
# Server2 example GRE to Server1
#    network::gre { 'gre1_example':
#      ensure    => 'present',
#      ipaddress => '172.16.16.1',
#      netmask   => '255.255.255.252',
#      method    => 'tunnel',
#      family    => 'inet',
#      onboot    => 'true',
#      dstaddr   => '172.16.16.2',
#      local     => '192.168.135.170',
#      endpoint  => '192.168.135.69',
#      ttl       => '255',
#      mode      => 'gre',
#    }
#
#
define network::gre(
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
  $dstaddr   = undef,
  $local     = undef,
  $endpoint  = undef,

  $mode      = "gre",
  $ttl       = "255",
) {

  case $::osfamily {
    Debian: {
      network::gre::debian { $name:
        ensure    => $ensure,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        method    => $method,
        family    => $family,
        onboot    => $onboot,
        dstaddr   => $dstaddr,
        local     => $local,
        endpoint  => $endpoint,

        mode      => $mode,
        ttl       => $ttl,

      }
    }

    default: {
      fail("network::bond does not support osfamily '${::osfamily}'")
    }
  }
}
