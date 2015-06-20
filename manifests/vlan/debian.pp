# = Define: network::vlan::debian
#
define network::vlan::debian(
  $raw_device,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
  $mtu       = undef,
  
  $ip_proxy_arp   = undef,
  $ip_rp_filter   = undef,
  $hw_mac_address = undef,

) {

  $raw = {
    'vlan-raw-device' => $raw_device,
    'ip-proxy-arp'    => $ip_proxy_arp,
    'ip-rp-filter'    => $ip_rp_filter,
    'hw-mac-address'  => $hw_mac_address,
  }

  $opts = compact_hash($raw)

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
