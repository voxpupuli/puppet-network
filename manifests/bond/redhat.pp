# = Define: network::bond::redhat
#
# Instantiate bonded interfaces on Redhat based systems.
#
# == See also
#
# * Red Hat Deployment Guide 25.7.2 "Using Channel Bonding" https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/sec-Using_Channel_Bonding.html
#
define network::bond::redhat(
  $slaves,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,

  $mode             = undef,
  $miimon           = undef,
  $downdelay        = undef,
  $updelay          = undef,
  $lacp_rate        = undef,
  $primary          = undef,
  $primary_reselect = undef,
  $xmit_hash_policy = undef,
) {

  $bonding_opts = template("network/bond/opts-redhat.erb")

  network_config { $name:
    ensure    => $ensure,
    method    => $method,
    ipaddress => $ipaddress,
    netmask   => $netmask,
    family    => $family,
    onboot    => $onboot,
    options          => {
      'BONDING_OPTS' => $bonding_opts,
    }
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

