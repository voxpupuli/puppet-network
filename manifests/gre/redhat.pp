# = Define: network::gre::redhat
#
# Instantiate GRE tunnel on Redhat based systems.
#
define network::gre::redhat(
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
) {

  $raw = {
    'PEER_OUTTER_IPADDR'  => $dstaddr,
    'MY_INNER_IPADDR'     => $local,
    'PEER_INNER_IPADDR'   => $endpoint,
    'TYPE'                => $mode,
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
