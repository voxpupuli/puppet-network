require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'network_route',
  docs: <<-EOS,
      Manage non-volatile route configuration information.
    EOS
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether the network route should be present or absent on the target system.',
      default: 'present',
    },
    prefix:        {
      type:      'String',
      desc:      'The destination prefix/network of the route.',
      behaviour: :namevar,
    },
    default_route: {
      type:      'Optional[Boolean]',
      desc:      'Whether the route is default or not.',
    },
    gateway:     {
      type:      'Optional[String]',
      desc:      'The gateway to use for the route.',
    },
    interface:   {
      type:      'Optional[String]',
      desc:      'The interface to use for the route.',
    },
    metric: {
      type:      'String',
      desc:      'preference value of the route. NUMBER is an arbitrary 32bit number.',
      default:   '100',
    },
    table: {
      type:      'Optional[String]',
      desc:      'table to add this route.',
    },
    source: {
      type:      'Optional[String]',
      desc:      'the source address to prefer using when sending to the destinations covered by route prefix.',
    },
    scope: {
      type:      'Optional[Enum["global", "nowhere", "host", "link", "site"]]',
      desc:      'scope of the destinations covered by the route prefix.',
    },
    protocol: {
      type:      'Enum["static", "redirect", "kernel", "boot", "ra"]',
      desc:      'routing protocol identifier of this route.',
      default:   'static',
    },
    mtu: {
      type:      'Optional[String]',
      desc:      'the MTU along the path to destination.',
    },
  },
)
