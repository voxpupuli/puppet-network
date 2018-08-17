# Deploys a network route to the system using ip route
# and adds the route to a file for persistence.
#
# @summary Manages network routes in both the table and persistent file
#
# @author Vox Pupuli <voxpupuli@groups.io>
#
# @example
#   network::route { '192.168.232.0/24':
#     ensure  => present
#     network => '192.168.232.0',
#     netmask => '24',
#     gateway => '192.168.100.1',
#   }
#
# @param network
#   IPv4 Network or Host ip address the route is pointing to.
# @param netmask
#   IPv4 CIDR address for the network/host destination route. If using host,
#   then the netmask should be '32'
# @param ensure
#   Ensure the route exists (or not)
# @param default_route
#   Is the route the default route?
# @param metric
#   Set the routing metric.
# @param protocol
#   Set the iproute2 protocol. 
#   Valid values are: 'static', 'dhcp', 'redirect', 'kernel', 'boot', 'ra'
# @param gateway
#   The network gateway to route through.
# @param interface
#   The Network Interface to route through.
# @param table
#   The iproute2 routing table to apply the route to.
# @param source
#   The source IP for which to apply the route to.
# @param scope
#   The iproute2 scope to apply.
#   Valid values: 'global', 'nowhere', 'host', 'link', 'site'
# @param mtu
#   The MTU to apply to the route.
#
define network::route(
  Stdlib::Ipv4 $network,
  Stdlib::Ipv4 $netmask,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $default_route = false,
  String $metric = '100',
  Enum['static', 'redirect', 'kernel', 'boot', 'ra', 'dhcp'] $protocol = 'static',
  Optional[Stdlib::Ipv4] $gateway,
  Optional[String] $interface,
  Optional[String] $table,
  Optional[Stdlib::Ipv4] $source,
  Optional[Enum['global', 'nowhere', 'host', 'link', 'site']] $scope,
  Optional[String] $mtu,
) {
  if $gateway == undef && $interface == undef {
    fail('Route must have a gateway or interface!')
  }

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
