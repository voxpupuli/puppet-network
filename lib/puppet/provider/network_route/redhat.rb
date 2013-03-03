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
    routes = []

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
        raise Puppet::Error, "Malformed redhat route file, cannot instantiate network_route resources"
      end

      new_route = {}

      if route[0] == "default"
        cidr_target = "default"

        new_route[:name]    = cidr_target
        new_route[:network] = "default"
        new_route[:netmask] = ''
        new_route[:gateway] = route[2]
        new_route[:interface] = route[4]
      else
        # use the CIDR version of the target as :name
        network, netmask = route[0].split("/")
        cidr_target = "#{network}/#{IPAddr.new(netmask).to_i.to_s(2).count('1')}"

        new_route[:name]    = cidr_target
        new_route[:network] = network
        new_route[:netmask] = netmask
        new_route[:gateway] = route[2]
        new_route[:interface] = route[4]
      end

      routes << new_route
    end

    routes
  end

  # Generate an array of sections
  def self.format_file(filename, providers)
    contents = []
    contents << header
    # Build routes
    providers.sort_by(&:name).each do |provider|
      [:network, :netmask, :gateway, :interface].each do |prop|
        raise Puppet::Error, "#{provider.name} does not have a #{property}." if provider.send(prop).nil?
      end
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
