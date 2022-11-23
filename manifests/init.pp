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

class network (
  $ifupdown_extra          = 'ifupdown-extra',
  $ifupdown_extra_provider = undef,
  $manage_ifupdown_extra   = true,
  $ensure_ifupdown_extra   = present,
) {
  if $facts['os']['family'] == 'Debian' and $manage_ifupdown_extra {
    package { $ifupdown_extra:
      ensure   => $ensure_ifupdown_extra,
      provider => $ifupdown_extra_provider,
    }
    Package[$ifupdown_extra] -> Network_route <| |>
  }
}
