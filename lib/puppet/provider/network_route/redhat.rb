require 'ipaddr'
require 'puppetx/filemapper'

Puppet::Type.type(:network_route).provide(:redhat) do
  # RHEL network_route routes provider.
  #
  # This provider uses the filemapper mixin to map the routes file to a
  # collection of network_route providers, and back.
  #
  # @see https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-static-routes.html

  include PuppetX::FileMapper

  desc "RHEL style routes provider"

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  def select_file
    "/etc/sysconfig/network-scripts/route-#{@resource[:interface]}"
  end

  def self.target_files
    Dir["/etc/sysconfig/network-scripts/route-*"]
  end


  def self.parse_file(filename, contents)
    # Build out an empty hash for new routes for storing their configs.
    route_hash = Hash.new do |hash, key|
      hash[key] = {}
      hash[key][:name] = key
      hash[key]
    end

    lines = contents.split("\n")
    lines.each do |line|
      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      if line =~ /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next
      end

      route = line.split
      if route.length < 4
        raise_malformed
      end
      if route[0] != "default"
        # use the CIDR version of the target as :name
        network, netmask = route[0].split("/")
        cidr_target = "#{network}/#{IPAddr.new(netmask).to_i.to_s(2).count('1')}"

        route_hash[cidr_target][:network] = network
        route_hash[cidr_target][:netmask] = netmask
        route_hash[cidr_target][:gateway] = route[2]
        route_hash[cidr_target][:interface] = route[4]
      else
        cidr_target = "default"
        route_hash[cidr_target][:network] = "default"
        route_hash[cidr_target][:netmask] = ''
        route_hash[cidr_target][:gateway] = route[2]
        route_hash[cidr_target][:interface] = route[4]
      end

    end

    route_hash.values
  end

  # Generate an array of sections
  def self.format_file(filename, providers)
    contents = []
    contents << header
    # Build routes
    providers.sort_by(&:name).each do |provider|
      raise Puppet::Error, "#{provider.name} does not have a network." if provider.network.nil?
      raise Puppet::Error, "#{provider.name} does not have a netmask." if provider.netmask.nil?
      raise Puppet::Error, "#{provider.name} does not have a gateway." if provider.gateway.nil?
      raise Puppet::Error, "#{provider.name} does not have an interface" if provider.interface.nil?
      if provider.network == "default"
        contents << "#{provider.network} via #{provider.gateway} dev #{provider.interface}\n"
      else
        contents << "#{provider.network}/#{provider.netmask} via #{provider.gateway} dev #{provider.interface}\n"
      end
    end
    contents.join
  end

  def self.header
    str = <<-HEADER
# HEADER: This file is is being managed by puppet. Changes to
# HEADER: routes that are not being managed by puppet will persist;
# HEADER: however changes to routes that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
    str
  end
end
