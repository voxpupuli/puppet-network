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
    ensure             => $ensure,
    ipaddress          => $ipaddress,
    netmask            => $netmask,
    family             => $family,
    onboot             => $onboot,
    options            => {
      'bond-mode'      => $mode,
      'bond-miimon'    => $miimon,
      'bond-downdelay' => $downdelay,
      'bond-updelay'   => $updelay,
      'bond-lacp-rate' => $lacp_rate,
      # These can't be supported yet since there isn't clean handling of `undef`
      #'bond-primary'          => $primary,
      #'bond-primary-reselect' => $primary_reselect,
      'bond-xmit-hash-policy'  => $xmit_hash_policy,
    },
  }

  network_config { $slaves:
    ensure      => absent,
    reconfigure => true,
    before      => Network_config[$name],
  }
}
