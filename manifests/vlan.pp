# = Define: network::vlan
#
# Instantiate cross-platform bonded interfaces
#
# == Parameters
#
# === interface parameters
#
# [*ensure*]
#
# The ensure value for the bonding interface.
#
# Default: present
#
# [*ipaddress*]
#
# The IPv4 address of the interface.
#
# [*netmask*]
#
# The IPv4 network mask of the interface.
#
# [*method*]
#
# The network configuration method.
#
# [*onboot*]
#
# Whether to bring the interface up on boot.
#
# VLAN options
# 
# [*vlan-raw-device*] devicename
#        Indicates  the  device  to  create the vlan on.  This is ignored
#        when the devicename is part of the vlan interface name.
#
# [*ip-proxy-arp*] 0|1
#        Turn proxy-arp off or on for this specific interface.  This also
#        works on plain ethernet like devices.
#
# [*ip-rp-filter*] 0|1|2
#        Set  the  return  path filter for this specific interface.  This
#        also works on plain ethernet like devices.
#
# [*hw-mac-address*] mac-address
#        This sets the mac address of the interface  before  bringing  it
#        up.   This  works on any device that allows setting the hardware
#        address with the ip command.


define network::vlan (
  $raw_device = undef,
  $ensure     = present,
  $ipaddress  = undef,
  $netmask    = undef,
  $method     = undef,
  $family     = undef,
  $onboot     = undef,
  $mtu        = undef,

  $ip_proxy_arp   = undef,
  $ip_rp_filter   = undef,
  $hw_mac_address = undef,
  
) {

  require network::vlan::setup

  case $::osfamily {
    Debian: {
      network::vlan::debian { $name:
        raw_device => $raw_device,
        ensure     => $ensure,
        ipaddress  => $ipaddress,
        netmask    => $netmask,
        method     => $method,
        family     => $family,
        onboot     => $onboot,
        mtu        => $mtu,        
      }
    }

    default: {
      fail("network::vlan does not support osfamily '${::osfamily}'")
    }
  }
}