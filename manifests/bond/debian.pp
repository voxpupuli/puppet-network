# @summary Instantiate bonded interfaces on Debian based systems
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
# @param mtu
#   The Maximum Transmission Unit size to use for bond interface and all slaves
# @param options
#   Hash with custom interfaces options
# @param slave_options
#   Hash with custom slave interfaces options
# @param mode
#   The interface bond mode
# @param miimon
#   The MII link monitoring frequency in milliseconds
# @param downdelay
#   The time in milliseconds, to wait before disabling a slave after a link failure
# @param updelay
#   The time in milliseconds to wait before enabling a slave after a link recovery
# @param lacp_rate
#   LACPDU packet transmission rate in 802.3ad mode
# @param primary
#   The primary interface to use when the mode is 'active-backup'
# @param primary_reselect
#   Specifies the reselection policy for the primary slave
# @param xmit_hash_policy
#   Selects the transmit hash policy to use for slave selection
#
# @see https://wiki.debian.org/Bonding Debian Network Bonding
#
define network::bond::debian (
  Array[String[1]]                        $slaves,
  Stdlib::Ensure::Package                 $ensure           = present,
  Optional[Stdlib::IP::Address::Nosubnet] $ipaddress        = undef,
  Optional[String[1]]                     $netmask          = undef,
  Optional[String[1]]                     $method           = undef,
  Optional[Enum['inet', 'inet6']]         $family           = undef,
  Optional[Boolean]                       $onboot           = undef,
  Optional[
    Variant[Boolean, Enum['true', 'false']]
  ]                                       $hotplug          = undef,
  Optional[
    Variant[Integer[42, 65536], Pattern[/^\d+$/]]
  ]                                       $mtu              = undef,
  Optional[Hash[String, Any]]             $options          = undef,
  Optional[Hash[String, Any]]             $slave_options    = undef,
  Optional[String[1]]                     $mode             = undef,
  Optional[String[1]]                     $miimon           = undef,
  Optional[String[1]]                     $downdelay        = undef,
  Optional[String[1]]                     $updelay          = undef,
  Optional[String[1]]                     $lacp_rate        = undef,
  Optional[String[1]]                     $primary          = undef,
  Optional[String[1]]                     $primary_reselect = undef,
  Optional[String[1]]                     $xmit_hash_policy = undef,
) {
  $raw = {
    'bond-slaves'           => join($slaves, ' '),
    'bond-mode'             => $mode,
    'bond-miimon'           => $miimon,
    'bond-downdelay'        => $downdelay,
    'bond-updelay'          => $updelay,
    'bond-lacp-rate'        => $lacp_rate,
    'bond-primary'          => $primary,
    'bond-primary-reselect' => $primary_reselect,
    'bond-xmit-hash-policy' => $xmit_hash_policy,
  }

  if $mtu =~ String {
    warning('$mtu should be an integer and will change in future releases')
  }
  if $mtu {
    # https://bugs.launchpad.net/ubuntu/+source/ifupdown/+bug/1224007
    $raw_post_up = { 'post-up' => "ip link set dev ${name} mtu ${mtu}", }
  } else {
    $raw_post_up = {}
  }

  $opts = network::compact_hash(merge($raw, $raw_post_up, $options))

  network_config { $name:
    ensure    => $ensure,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    method    => $method,
    onboot    => $onboot,
    hotplug   => $hotplug,
    options   => $opts,
  }

  network_config { $slaves:
    ensure      => absent,
    reconfigure => true,
    before      => Network_config[$name],
  }
}
