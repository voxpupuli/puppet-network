# = Define: network::bond::debian
#
# Instantiate bonded interfaces on Debian based systems.
#
# == See also
#
# * Debian Network Bonding http://wiki.debian.org/Bonding
define network::bond::debian(
  $slaves,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,

  $mode             = undef,
  $miimon           = undef,
  $downdelay        = undef,
  $updelay          = undef,
  $lacp_rate        = undef,
  $primary          = undef,
  $primary_reselect = undef,
  $xmit_hash_policy = undef,
) {

  $raw = {
    'bond-slaves'    => join($slaves, ' '),
    'bond-mode'      => $mode,
    'bond-miimon'    => $miimon,
    'bond-downdelay' => $downdelay,
    'bond-updelay'   => $updelay,
    'bond-lacp-rate' => $lacp_rate,
    'bond-primary'   => $primary,
    'bond-primary-reselect' => $primary_reselect,
    'bond-xmit-hash-policy' => $xmit_hash_policy,
  }

  $opts = compact_hash($raw)

  network_config { $name:
    ensure    => $ensure,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    method    => $method,
    onboot    => $onboot,
    options   => $opts,
  }

  network_config { $slaves:
    ensure      => absent,
    reconfigure => true,
    before      => Network_config[$name],
  }
}
