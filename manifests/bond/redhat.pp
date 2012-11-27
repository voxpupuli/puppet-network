# = Define: network::bond::redhat
#
# Instantiate bonded interfaces on Debian based systems.
#
# ==
define network::bond::redhat(
  $slaves,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
) {

  network_config { $name:
    ensure    => $ensure,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    onboot    => $onboot,
  }

  network_config { $slaves:
    ensure => $ensure,
    method => static,
    onboot => true,
    options    => {
      'MASTER' => $name,
      'SLAVE'  => 'yes',
    }
  }
}

