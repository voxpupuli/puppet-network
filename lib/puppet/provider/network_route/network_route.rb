require 'net/ip'
# require_relative '../../../puppet_x/voxpupuli/utils'
require 'puppet/resource_api/simple_provider'

# Implementation for the network_route type using the Resource API.
class Puppet::Provider::NetworkRoute::NetworkRoute
  # include PuppetX::FileMapper

  def routes_list
    routes = []
    Net::IP.routes.each do |route|
      routes.push(route.instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete("@")] = route.instance_variable_get(var) })
    end
    routes
  end

  def get(_context)
    routes_list.map do |route|
      default = if route['prefix'] == 'default'
                  true
                else
                  false
                end

      {
        ensure: 'present',
        prefix: route['prefix'],
        default_route: default,
        gateway: route['via'],
        interface: route['dev'],
        metric: route['metric'],
        table: route['table'],
        source: route['src'],
        scope: route['scope'],
        protocol: route['proto'],
        mtu: route['mtu']
      }.compact!
    end
  end

  def puppet_munge(should)
    should.delete(:ensure)
    if should[:default_route]
      should[:prefix] = 'default'
      should.delete(:default_route)
      should.delete(:prefix)
    else
      should[:prefix] = should.delete(:prefix)
    end
    should[:via] = should.delete(:gateway) if should[:gateway]
    should[:dev] = should.delete(:interface) if should[:interface]
    should[:metric] = should.delete(:metric)
    should[:table] = should.delete(:table)
    should[:src] = should.delete(:source) if should[:source]
    should[:scope] = should.delete(:scope)
    should[:proto] = should.delete(:protocol)
    should[:mtu] = should.delete(:mtu) if should[:mtu]
    should
  end
end
