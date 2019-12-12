# = Define: network::bond
#
# Instantiate cross-platform bonded interfaces
#
# == Parameters
#
# === interface parameters
#
# [*ensure*]
#
# The ensure value for the bonding interface.
#
# Default: present
#
# [*ipaddress*]
#
# The IPv4 address of the interface.
#
# [*netmask*]
#
# The IPv4 network mask of the interface.
#
# [*method*]
#
# The network configuration method.
#
# [*onboot*]
#
# Whether to bring the interface up on boot.
#
# [*hotplug*]
#
# Whether to allow hotplug for the interface.
#
# [*mtu*]
#
# The Maximum Transmission Unit size to use for bond interface and all slaves.
#
# [*options*]
#
# Hash with custom interfaces options.
#
# [*slave_options*]
#
# Hash with custom slave interfaces options.
#
# === bonding parameters
#
# [*slaves*]
#
# A list of slave interfaces to combine for the bonded interface.
#
# [*mode*]
#
# The interface bond mode. The value can be either the human readable term,
# such as 'active-backup' or the numeric representation, such as '1'.
#
# Default: 'active-backup'
#
# Options:
#   - balance-rr/0
#   - active-backup/1
#   - blancer-xor/2
#   - broadcast/3
#   - 802.3ad/4
#   - balance-tlb/5
#   - balance-alb/6
#
# [*miimon*]
#
# The MII link monitoring frequency in milliseconds.
#
# Default: 100
#
# [*downdelay*]
#
# The time in milliseconds, to wait before disabling a slave after a link
# failure has been detected.
#
# Default: 200
#
# [*updelay*]
#
# The time in millisceonds to wait before enabling a slave after a link
# recovery has been detected.
#
# [*lacp_rate*]
#
#
# Option specifying the rate in which we'll ask our link partner to transmit
# LACPDU packets in 802.3ad mode. Only applicable when mode is '802.3ad'.
#
# Options:
#   - slow/0: Request partner to transmit LACPDUs every 30 seconds
#   - fast/1: Request partner to transmit LACPDUs every 1 second
#
#
# [*primary*]
#
# The primary interface to use when the mode is 'active-backup'. All other
# interfaces will be offline by default. Only applicable when mode is '802.3ad'.
#
# Default: $slaves[0]
#
# [*primary_reselect*]
#
# Specifies the reselection policy for the primary slave. This affects how
# the primary slave is chosen to become the active slave when failure of the
# active slave or recovery of the primary slave occurs. This option is
# designed to prevent flip-flopping between the primary slave and other slaves.
#
# Options:
#   - always/0
#   - better/1
#   - failure/2
#
# [*xmit_hash_policy*]
#
# Selects the transmit hash policy to use for slave selection in balance-xor
# and 802.3ad modes.
#
# Options:
#   - layer2
#   - layer2+3
#   - layer3+4
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
  $ensure           = present,
  $ipaddress        = undef,
  $netmask          = undef,
  $method           = undef,
  $family           = undef,
  $onboot           = undef,
  $hotplug          = undef,
  $lacp_rate        = undef,
  $mtu              = undef,
  $options          = undef,
  $slave_options    = undef,

  $mode             = 'active-backup',
  $miimon           = '100',
  $downdelay        = '200',
  $updelay          = '200',
  $primary          = $slaves[0],
  $primary_reselect = 'always',
  $xmit_hash_policy = 'layer2',
) {

  require network::bond::setup

  kmod::alias { $name:
    ensure => $ensure,
    source => 'bonding',
  }

  case $facts['os']['family'] {
    'Debian': {
      network::bond::debian { $name:
        ensure           => $ensure,
        slaves           => $slaves,
        ipaddress        => $ipaddress,
        netmask          => $netmask,
        method           => $method,
        family           => $family,
        onboot           => $onboot,
        hotplug          => $hotplug,
        mtu              => $mtu,
        options          => $options,
        slave_options    => $slave_options,

        mode             => $mode,
        miimon           => $miimon,
        downdelay        => $downdelay,
        updelay          => $updelay,
        lacp_rate        => $lacp_rate,
        primary          => $primary,
        primary_reselect => $primary_reselect,
        xmit_hash_policy => $xmit_hash_policy,

        require          => Kmod::Alias[$name],
      }
    }
    'RedHat': {
      network::bond::redhat { $name:
        ensure           => $ensure,
        slaves           => $slaves,
        ipaddress        => $ipaddress,
        netmask          => $netmask,
        family           => $family,
        method           => $method,
        onboot           => $onboot,
        hotplug          => $hotplug,
        mtu              => $mtu,
        options          => $options,
        slave_options    => $slave_options,

        mode             => $mode,
        miimon           => $miimon,
        downdelay        => $downdelay,
        updelay          => $updelay,
        lacp_rate        => $lacp_rate,
        primary          => $primary,
        primary_reselect => $primary_reselect,
        xmit_hash_policy => $xmit_hash_policy,

        require          => Kmod::Alias[$name],
      }
    }
    default: {
      fail("network::bond does not support osfamily '${facts['os']['family']}'")
    }
  }
}
