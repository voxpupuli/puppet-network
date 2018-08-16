require 'net/ip'
require 'puppet/resource_api/simple_provider'

# Implementation for the network_route type using the Resource API.
class Puppet::Provider::NetworkRoute::NetworkRoute
  # include PuppetX::FileMapper

  def routes_list
    routes = []
    Net::IP.routes.each do |route|
      routes.push(route.to_h)
    end
    routes
  end

  def get(_context)
    routes_list.map do |route|
      default = if route[:prefix] == 'default'
                  true
                else
                  false
                end

      {
        ensure: 'present',
        prefix: route[:prefix],
        default_route: default,
        gateway: route[:via],
        interface: route[:dev],
        metric: route[:metric],
        table: route[:table],
        source: route[:src],
        scope: route[:scope],
        protocol: route[:proto],
        mtu: route[:mtu]
      }.compact!
    end
  end

  def puppet_munge(should)
    should.delete(:ensure)
    if should[:default_route]
      should[:prefix] = 'default'
      should.delete(:default_route)
    else
      should[:prefix] = should.delete(:prefix)
    end
    should[:via] = should.delete(:gateway) if should[:gateway]
    should[:dev] = should.delete(:interface) if should[:interface]
    should[:metric] = should.delete(:metric)
    should[:table] = should.delete(:table) if should[:table]
    should[:src] = should.delete(:source) if should[:source]
    should[:scope] = should.delete(:scope) if should[:scope]
    should[:proto] = should.delete(:protocol)
    should[:mtu] = should.delete(:mtu) if should[:mtu]
    should
  end

  def set(context, changes)
    changes.each do |name, change|
      is = change.key?(:is) ? change[:is] : get_single(name)
      should = change[:should]

      is = { prefix: name, ensure: 'absent' } if is.nil?
      should = { prefix: name, ensure: 'absent' } if should.nil?

      if is[:ensure].to_s == 'absent' && should[:ensure].to_s == 'present'
        create(context, name, should)
      elsif is[:ensure] == should[:ensure] && is != should
        update(context, name, should)
      elsif is[:ensure].to_s == 'present' && should[:ensure].to_s == 'absent'
        delete(context, name, should)
      end
    end
  end

  def create(context, name, should)
    puppet_munge(should)
    route = Net::IP::Route.new(should)
    Net::IP.routes.add(route)
  end

  def update(context, name, should)
    puppet_munge(should)
    route = Net::IP::Route.new(should)
    Net::IP.routes.flush(route.prefix)
    Net::IP.routes.add(route)
  end

  def delete(context, name, should)
    puppet_munge(should)
    route = Net::IP::Route.new(should)
    Net::IP.routes.flush(route.prefix)
  end
end
