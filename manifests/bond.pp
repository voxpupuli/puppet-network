# @summary Instantiate cross-platform bonded interfaces
#
# @param slaves
#   A list of slave interfaces to combine for the bonded interface
# @param ensure
#   The ensure value for the bonding interface
# @param ipaddress
#   The IPv4 address of the interface
# @param netmask
#   The IPv4 network mask of the interface
# @param method
#   The network configuration method
# @param family
#   The IP family (inet or inet6)
# @param onboot
#   Whether to bring the interface up on boot
# @param hotplug
#   Whether to allow hotplug for the interface
# @param lacp_rate
#   Option specifying the rate in which we'll ask our link partner to transmit
#   LACPDU packets in 802.3ad mode. Only applicable when mode is '802.3ad'.
#   Options: slow/0 (every 30 seconds), fast/1 (every 1 second)
# @param mtu
#   The Maximum Transmission Unit size to use for bond interface and all slaves
# @param options
#   Hash with custom interfaces options
# @param slave_options
#   Hash with custom slave interfaces options
# @param mode
#   The interface bond mode. The value can be either the human readable term,
#   such as 'active-backup' or the numeric representation, such as '1'.
#   Options: balance-rr/0, active-backup/1, balance-xor/2, broadcast/3,
#   802.3ad/4, balance-tlb/5, balance-alb/6
# @param miimon
#   The MII link monitoring frequency in milliseconds
# @param downdelay
#   The time in milliseconds, to wait before disabling a slave after a link
#   failure has been detected
# @param updelay
#   The time in milliseconds to wait before enabling a slave after a link
#   recovery has been detected
# @param primary
#   The primary interface to use when the mode is 'active-backup'. All other
#   interfaces will be offline by default. Only applicable when mode is '802.3ad'
# @param primary_reselect
#   Specifies the reselection policy for the primary slave. This affects how
#   the primary slave is chosen to become the active slave when failure of the
#   active slave or recovery of the primary slave occurs. This option is
#   designed to prevent flip-flopping between the primary slave and other slaves.
#   Options: always/0, better/1, failure/2
# @param xmit_hash_policy
#   Selects the transmit hash policy to use for slave selection in balance-xor
#   and 802.3ad modes. Options: layer2, layer2+3, layer3+4
#
# @example
#   network::bond { 'bond0':
#     ipaddress => '172.16.1.2',
#     netmask   => '255.255.128.0',
#     ensure    => present,
#     slaves    => ['eth0', 'eth1'],
#   }
#
# @see https://www.kernel.org/doc/Documentation/networking/bonding.txt Linux Ethernet Bonding Driver HOWTO, Section 2 "Bonding Driver Options"
#
define network::bond (
  Array[String[1]]                                   $slaves,
  Stdlib::Ensure::Package                            $ensure             = present,
  Optional[Stdlib::IP::Address::V4]                  $ipaddress          = undef,
  Optional[String[1]]                                $netmask            = undef,
  Optional[String[1]]                                $method             = undef,
  Optional[Enum['inet', 'inet6']]                    $family             = undef,
  Optional[Boolean]                                  $onboot             = undef,
  Variant[Boolean, Enum['true', 'false'], Undef]     $hotplug            = undef,
  Optional[Enum['slow', 'fast', '0', '1']]           $lacp_rate          = undef,
  Optional[
    Variant[Integer[42, 65536], Pattern[/^\d+$/]]
  ]                                                  $mtu                = undef,
  Optional[Hash[String, Any]]                        $options            = undef,
  Optional[Hash[String, Any]]                        $slave_options      = undef,
  Enum[
    'balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad',
    'balance-tlb', 'balance-alb', '0', '1', '2', '3','4', '5', '6'
  ]                                                  $mode               = 'active-backup',
  String[1]                                          $miimon             = '100',
  String[1]                                          $downdelay          = '200',
  String[1]                                          $updelay            = '200',
  String[1]                                          $primary            = $slaves[0],
  Enum['always', 'better', 'failure', '0', '1', '2'] $primary_reselect   = 'always',
  Enum['layer2', 'layer2+3', 'layer3+4']             $xmit_hash_policy   = 'layer2',
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
