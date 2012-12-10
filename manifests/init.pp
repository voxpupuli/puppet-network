# == Class: network
#
# The network manages interface configurations so you don't have to.
#
# ===Required hiera keys:
# network:
# === Examples
#
#  class { network:
#  }
# hiera keys should be a hash of interface configurations which are then realized onto the server IE:
#network:
#  eth1: {
#    ensure    => 'present',
#    family    => 'inet',
#    ipaddress => '169.254.0.1',
#    method    => 'static',
#    netmask   => '255.255.0.0',
#    onboot    => 'true',
#  }
#network_bond:
#  bond0: {
#    ensure:      'present',
#    onboot:      'true',
#    ipaddress:   '10.10.10.99',
#    netmask:     '255.255.255.0',
#    bonding_opts: '"mode=1 arp_interval=1000 arp_ip_target=10.10.10.1"',
#    method:    'static',
#    family: 'inet',
#    slaves:  ['eth0', 'eth1']
#  } 
#
# === Authors
#
# Adrien Thebo <adrien@puppetlabs.com>
# Wolf Noble <wnoble@datapipe.com>
#
#
# === Copyright
#
class network{
  anchor { 'network::begin':}
  -> anchor {'network::config::begin':}
  -> anchor {'network::config::end':}
  -> anchor {'network::end':}
  case $::osfamily {
    redhat, debian: {
      #this module really only applies for rhel and debian variants. Don't let it get included otherwise.
      class { 'network::params': hiera_enabled => $::hiera_enabled }
      #set a global variable hiera_enabled to true if you wish to use this as is
      #otherwise just set the parameter to true here
      if $network::params::netconfig {
        create_resources('network_config', $network::params::netconfig)
      }
      if $network::params::netconfig_bond {
        include kmod
        create_resources('network::bond', $network::params::netconfig_bond)
      }
    }#end supported variant case
    default: {
      notice "there is not an interface creation method for $::operatingsystem for $::fqdn."
    }#end default case
  }#end OS case
}

