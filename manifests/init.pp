# Manage network configuration and routing on Linux systems with the
# network_route and network_config resources. This also installs the
# packages and gems needed to manage these settings.
#
# @summary Manage linux network configuration and routes
#
# @author Vox Pupuli <voxpupuli@groups.io>
#
# @example
#   include network
#
# @param ifupdown_extra
#   The name of the ifupdown-extra package
#
# @param ifupdown_extra_provider
#   The provider of the ifupdown-extra package
#
# @param manage_ifupdown_extra
#   Whether this class should manage the ifupdown-extra package
#
# @param ensure_ifupdown_extra
#   What state the ifupdown-extra package should be in
#
# @param ipaddress
#   The name of the ipaddress gems
#
# @param ipaddress_provider
#   The provider of the ipaddress gem
#
# @param manage_ipaddress
#   Whether this class should manage the ipaddress gem
#
# @param ensure_ipaddress
#   What state the ifupdown-extra package should be in
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

  if $::osfamily == 'Debian' and $manage_ifupdown_extra {
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
