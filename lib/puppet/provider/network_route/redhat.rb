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

  desc 'RHEL style routes provider'

  confine osfamily: :redhat
  defaultfor osfamily: :redhat

  has_feature :provider_options

  def select_file
    "/etc/sysconfig/network-scripts/route-#{@resource[:interface]}"
  end

  def self.target_files
    Dir['/etc/sysconfig/network-scripts/route-*']
  end

  def self.parse_file(_filename, contents)
    routes = []

    lines = contents.split("\n")
    lines.each do |line|
      # Strip off any trailing comments
      line.sub!(%r{#.*$}, '')

      if line =~ %r{^\s*#|^\s*$}
        # Ignore comments and blank lines
        next
      end

      route = line.split(' ', 6)
      if route.length < 4
        raise Puppet::Error, 'Malformed redhat route file, cannot instantiate network_route resources'
      end

      new_route = {}

      new_route[:gateway] = route[2]
      new_route[:interface] = route[4]
      new_route[:options] = route[5] if route[5]

      if route[0] == 'default'
        cidr_target = 'default'

        new_route[:name]    = cidr_target
        new_route[:network] = 'default'
        new_route[:netmask] = '0.0.0.0'
      else
        # use the CIDR version of the target as :name
        network, netmask = route[0].split('/')
        cidr_target = "#{network}/#{IPAddr.new(netmask).to_i.to_s(2).count('1')}"

        new_route[:name]    = cidr_target
        new_route[:network] = network
        new_route[:netmask] = netmask
      end

      routes << new_route
    end

    routes
  end

  # Generate an array of sections
  def self.format_file(_filename, providers)
    contents = []
    contents << header
    # Build routes
    providers.sort_by(&:name).each do |provider|
      %i[network netmask gateway interface].each do |prop|
        raise Puppet::Error, "#{provider.name} is missing the required parameter '#{prop}'." if provider.send(prop).nil?
      end
      contents << if provider.network == 'default'
                    "#{provider.network} via #{provider.gateway} dev #{provider.interface}"
                  else
                    "#{provider.network}/#{provider.netmask} via #{provider.gateway} dev #{provider.interface}"
                  end
      contents << (provider.options == :absent ? "\n" : " #{provider.options}\n")
    end
    contents.join
  end

  def self.header
    str = <<-HEADER
# HEADER: This file is being managed by puppet. Changes to
# HEADER: routes that are not being managed by puppet will persist;
# HEADER: however changes to routes that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
    str
  end
end
