# @summary Install the packages and gems required by the network_route and network_config resources
#
# @param ifupdown_extra
#   The name of the ifupdown-extra package
# @param ifupdown_extra_provider
#   The provider of the ifupdown-extra package
# @param manage_ifupdown_extra
#   Whether this class should manage the ifupdown-extra package
# @param ensure_ifupdown_extra
#   What state the ifupdown-extra package should be in
# @param ipaddress
#   The name of the ipaddress gems
# @param ipaddress_provider
#   The provider of the ipaddress gem
# @param manage_ipaddress
#   Whether this class should manage the ipaddress gem
# @param ensure_ipaddress
#   What state the ipaddress package should be in
# @param manage_nmstate
#   Whether this class should manage the nmstate package
# @param nmstate
#   The name of the nmstate package
# @param ensure_nmstate
#   What state the nmstate package should be in
#
class network (
  String[1]               $ifupdown_extra          = 'ifupdown-extra',
  Optional[String[1]]     $ifupdown_extra_provider = undef,
  Boolean                 $manage_ifupdown_extra   = true,
  Stdlib::Ensure::Package $ensure_ifupdown_extra   = present,
  String[1]               $ipaddress               = 'ipaddress',
  String[1]               $ipaddress_provider      = 'puppet_gem',
  Boolean                 $manage_ipaddress        = true,
  Stdlib::Ensure::Package $ensure_ipaddress        = absent,
  Boolean                 $manage_nmstate          = false,
  String[1]               $nmstate                 = 'nmstate',
  Stdlib::Ensure::Package $ensure_nmstate          = present,
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

  if $manage_nmstate {
    package { $nmstate:
      ensure => $ensure_nmstate,
    }
    Package[$nmstate] -> Network_config <| |>
  }
}
