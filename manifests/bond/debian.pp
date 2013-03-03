# = Define: network::bond::debian
#
# Instantiate bonded interfaces on Debian based systems.
#
# ==
define network::bond::debian(
  $slaves,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,

  $mode,
  $miimon,
  $downdelay,
  $updelay,
  $lacp_rate,
  $primary,
  $primary_reselect,
  $xmit_hash_policy,
) {

  network_config { $name:
    ensure    => $ensure,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    onboot    => $onboot,
  }

  network_config { $slaves:
    ensure      => absent,
    reconfigure => true,
    before      => Network_config[$name],
  }
}
