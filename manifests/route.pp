# Deploys a network route to the system using ip route
# and adds the route to a file for persistence.
#
# @summary A short summary of the purpose of this class
#
# @example
#   include network::route
define network::route(
  Stdlib::Ipv4 $network,
  Stdlib::Ipv4 $netmask,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $default_route = false,
  String $metric = '100',
  String $protocol = 'static',
  Optional[Stdlib::Ipv4] $gateway,
  Optional[String] $interface,
  Optional[String] $table,
  Optional[Stdlib::Ipv4] $source,
  Optional[Enum['global', 'nowhere', 'host', 'link', 'site']] $scope,
  Optional[String] $mtu,
) {
  $route_file = case $facts['os']['name'] {
    'Debian': {
      '/etc/network/routes'
    }
    'Ubuntu': {
      if $facts['os']['release']['full'] == '18.04' {
        '/etc/network/routes'
      } else {
        '/etc/network/routes'
      }
    }
    /RedHat|CentOS/: {
      "/etc/sysconfig/network-scripts/route-${interface}"
    }
    default: {
      fail("Network::Route is not compatible with ${facts['os']['family']}!")
    }
  }

  file { $route_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("network/routes/${facts['os']['family'].downcase}.erb"),
  }

  network_route { "${network}/${netmask}":
    ensure        => $ensure,
    default_route => $default_route,
    gateway       => $gateway,
    interface     => $interface,
    metric        => $metric,
    table         => $table,
    source        => $source,
    scope         => $scope,
    protocol      => $protocol,
    mtu           => $mtu,
  }
}
