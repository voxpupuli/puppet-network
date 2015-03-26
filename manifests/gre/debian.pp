# = Define: network::gre::debian
#
# Instantiate GRE tunnel on Debian based systems.
#
define network::gre::debian(
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
  $dstaddr   = undef,
  $local     = undef,
  $endpoint  = undef,

  $mode      = undef,
  $ttl       = undef,
) {

  $raw = {
    'dstaddr'  => $dstaddr,
    'local'    => $local,
    'endpoint' => $endpoint,
    'mode'     => $mode,
    'ttl'      => $ttl,
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

}
