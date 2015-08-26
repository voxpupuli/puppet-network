# = Define: network::bridge::debian
#
define network::bridge::debian(
  $ports,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
  $mtu       = undef,
  $options   = undef,

  $ageing     = undef,
  $bridgeprio = undef,
  $fd         = undef,
  $gcint      = undef,
  $hello      = undef,
  $hw         = undef,
  $maxage     = undef,
  $maxwait    = undef,
  $pathcost   = undef,
  $portprio   = undef,
  $stp        = undef,
  $waitport   = undef,  
) {

  $raw = {
      'bridge_ports'      => join($ports, ' '),
      'bridge_ageing'     => $ageing,
      'bridge_bridgeprio' => $bridgeprio,
      'bridge_fd'         => $fd,
      'bridge_gcint'      => $gcint,
      'bridge_hello'      => $hello,
      'bridge_hw'         => $hw,
      'bridge_maxage'     => $maxage,
      'bridge_maxwait'    => $maxwait,
      'bridge_pathcost'   => $pathcost,
      'bridge_portprio'   => $portprio,
      'bridge_stp'        => $stp,
      'bridge_waitport'   => $waitport,
  }

  $opts = compact_hash(merge($raw, $options))

  network_config { $name:
    ensure    => $ensure,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    method    => $method,
    onboot    => $onboot,
    mtu       => $mtu,
    options   => $opts,
  }

}
