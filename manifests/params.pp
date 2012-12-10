# == Class: network::params
#
# The network manages custom yum repositories.
# This module sets parameters from either hiera or local
# === Parameters
# see network class for details
#
# === Authors
# Adrien Thebo <adrien@puppetlabs.com>
# Wolf Noble <wnoble@datapipe.com>
#
# === Copyright
#
# Copyright 2012 Datapipe, unless otherwise noted.
#

class network::params($hiera_enabled=false){
  if $hiera_enabled {
    $netconfig           = hiera('network','')
    $netconfig_bond      = hiera('network_bond','')
  }#end hiera enabled
  else {
    $netconfig       = ''
    $netconfig_bond  = ''
  }
}
