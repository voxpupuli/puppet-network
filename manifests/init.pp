# = Class: network
#
# Install the packages and gems required by the network_route and network_config resources
#
# == Parameters
#
# [*ifupdown_extra*]
#
# The name of the ifupdown-extra package
#
# Default: ifupdown-extra
#
# [*ifupdown_extra_provider*]
#
# The provider of the ifupdown-extra package
#
# Default: undef
#
# [*manage_ifupdown_extra*]
#
# Whether this class should manage the ifupdown-extra package
#
# Default: true
#
# [*ensure_ifupdown_extra*]
#
# What state the ifupdown-extra package should be in
#
# Default: present
#
# [*ipaddress*]
#
# The name of the ipaddress gems
#
# Default: ipaddress
#
# [*ipaddress_provider*]
#
# The provider of the ipaddress gem
#
# Default: gem
#
# [*manage_ipaddress*]
#
# Whether this class should manage the ipaddress gem
#
# Default: true
#
# [*ensure_ipaddress*]
#
# What state the ifupdown-extra package should be in
#
# Default: present
#

class network(
  $ifupdown_extra          = 'ifupdown-extra',
  $ifupdown_extra_provider = undef,
  $manage_ifupdown_extra   = true,
  $ensure_ifupdown_extra   = present,
  $ipaddress               = 'ipaddress',
  $ipaddress_provider      = 'puppet_gem',
  $manage_ipaddress        = true,
  $ensure_ipaddress        = present,
) {

  if $facts['os']['family'] == 'Debian' and $manage_ifupdown_extra {
    package { $ifupdown_extra:
      ensure   => $ensure_ifupdown_extra,
      provider => $ifupdown_extra_provider,
    }
    Package[$ifupdown_extra] -> Network_route <| |>
  }

  if $manage_ipaddress {
    package { $ipaddress:
      ensure   => $ensure_ipaddress,
      provider => $ipaddress_provider,
    }
    Package[$ipaddress] -> Network_config <| |>
  }

}
