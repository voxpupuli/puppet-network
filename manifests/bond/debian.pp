# = Define: network::bond::debian
#
# Instantiate bonded interfaces on Debian based systems.
#
# == Notes
#
# systemd-networkd and netplan need to be disabled or removed on
# recent versions of Ubuntu at least, as they conflict with static
# network configs in /etc/network/interfaces which this uses.
#
# == See also
#
# * Debian Network Bonding http://wiki.debian.org/Bonding
define network::bond::debian (
  $slaves,
  $ensure                                           = present,
  $ipaddress                                        = undef,
  $netmask                                          = undef,
  $method                                           = undef,
  $family                                           = undef,
  $onboot                                           = undef,
  $hotplug                                          = undef,
  Optional[Variant[Integer[42, 65536],String]] $mtu = undef,
  $options                                          = undef,
  $slave_options                                    = undef,
  $mode                                             = undef,
  $miimon                                           = undef,
  $downdelay                                        = undef,
  $updelay                                          = undef,
  $lacp_rate                                        = undef,
  $primary                                          = undef,
  $primary_reselect                                 = undef,
  $xmit_hash_policy                                 = undef,
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

  $opts = compact_hash(merge($raw, $raw_post_up, $options))

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

  $opts_slave = merge( {
      'bond-master' => $name,
    },
    $slave_options
  )

  network_config { $slaves:
    ensure  => $ensure,
    method  => 'manual',
    onboot  => true,
    hotplug => false,
    options => $opts_slave,
  }
}
