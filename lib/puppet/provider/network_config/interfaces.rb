require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:interfaces) do
  # Debian network_config interfaces provider.
  #
  # This provider uses the filemapper mixin to map the interfaces file to a
  # collection of network_config providers, and back.
  #
  # @see http://wiki.debian.org/NetworkConfiguration
  # @see http://packages.debian.org/squeeze/ifupdown

  include PuppetX::FileMapper

  desc "Debian interfaces style provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

  has_feature :provider_options
  has_feature :hotpluggable

  def select_file
    '/etc/network/interfaces'
  end

  def self.target_files
    ['/etc/network/interfaces']
  end

  class MalformedInterfacesError < Puppet::Error
    def initialize(msg = nil)
      msg = 'Malformed debian interfaces file; cannot instantiate network_config resources' if msg.nil?
      super
    end
  end

  def self.raise_malformed
    @failed = true
    raise MalformedInterfacesError
  end

  class Instance

    attr_reader :name

    # Booleans
    attr_accessor :onboot, :hotplug


    # These fields are going to get rearranged to resolve issue 16
    # https://github.com/adrienthebo/puppet-network/issues/16
    attr_accessor :ipaddress, :netmask, :family, :method, :mtu, :mode

    # Options hash
    attr_reader :options

    def initialize(name)
      @name = name

      @options = Hash.new {|hash, key| hash[key] = []}
    end

    def to_hash
      h = {
        :name      => @name,
        :onboot    => @onboot,
        :hotplug   => @hotplug,
        :ipaddress => @ipaddress,
        :netmask   => @netmask,
        :family    => @family,
        :method    => @method,
        :mtu       => @mtu,
        :mode      => @mode,
        :options   => squeeze_options
      }

      h.inject({}) do |hash, (key, val)|
        hash[key] = val unless val.nil?
        hash
      end
    end

    def squeeze_options
      @options.inject({}) do |hash, (key, value)|
        if value.size <= 1
          hash[key] = value.pop
        else
          hash[key] = value
        end

      hash
      end
    end

    class << self

      def reset!
        @interfaces = {}
      end

      # @return [Array<Instance>] All class instances
      def all_instances
        @interfaces ||= {}
        @interfaces
      end

      def [](name)
        if all_instances[name]
          obj = all_instances[name]
        else
          obj = self.new(name)
          all_instances[name] = obj
        end

        obj
      end
    end
  end

  def self.parse_file(filename, contents)
    # Debian has a very irregular format for the interfaces file. The
    # parse_file method is somewhat derived from the ifup executable
    # supplied in the debian ifupdown package. The source can be found at
    # http://packages.debian.org/squeeze/ifupdown


    # The debian interfaces implementation requires global state while parsing
    # the file; namely, the stanza being parsed as well as the interface being
    # parsed.
    status = :none
    current_interface = nil

    lines = contents.split("\n")
    # TODO Join lines that end with a backslash

    # Iterate over all lines and determine what attributes they create
    lines.each do |line|

      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      case line
      when /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next

      when /^auto|^allow-auto/
        # Parse out any auto sections
        interfaces = line.split(' ')
        interfaces.delete_at(0)

        interfaces.each do |name|
          Instance[name].onboot = true
        end

        # Reset the current parse state
        current_interface = nil

      when /^allow-hotplug/
        # parse out allow-hotplug lines

        interfaces = line.split(' ')
        interfaces.delete_at(0)

        interfaces.each do |name|
          Instance[name].hotplug = true
        end

        # Don't reset Reset the current parse state
      when /^iface/

        # Format of the iface line:
        #
        # iface <iface> <family> <method>
        # zero or more options for <iface>

        if match = line.match(/^iface\s+(\S+)\s+(\S+)\s+(\S+)/)
          name   = match[1]
          family = match[2]
          method = match[3]

          # If an iface block for this interface has been seen, the file is
          # malformed.
          raise_malformed if Instance[name] and Instance[name].family

          status = :iface
          current_interface = name

          # This is done automatically
          #Instance[name].name   = name
          Instance[name].family = family
          Instance[name].method = method
          # for the vlan naming conventions (a mess), see
          # man 5 vlan-interfaces
          case name
            # 'vlan22'
            when /^vlan/
              Instance[name].mode   = :vlan
            # 'eth2.0003' or 'br1.2'
            when /^[a-z]{1,}[0-9]{1,}\.[0-9]{1,4}/
              Instance[name].mode   = :vlan
            else
              Instance[name].mode   = :raw
          end
        else
          # If we match on a string with a leading iface, but it isn't in the
          # expected format, malformed blar blar
          raise_malformed
        end

      when /^mapping/

        # XXX dox
        raise Puppet::DevError, "Debian interfaces mapping parsing not implemented."
        status = :mapping

      else
        # We're currently examining a line that is within a mapping or iface
        # stanza, so we need to validate the line and add the options it
        # specifies to the known state of the interface.

        case status
        when :iface
          if match = line.match(/(\S+)\s+(\S.*)/)
            # If we're parsing an iface stanza, then we should receive a set of
            # lines that contain two or more space delimited strings. Append
            # them as options to the iface in an array.

            key = match[1]
            val = match[2]

            name = current_interface

            case key
            when 'address';         Instance[name].ipaddress    = val
            when 'netmask';         Instance[name].netmask      = val
            when 'mtu';             Instance[name].mtu          = val
            else                    Instance[name].options[key] << val
            end
          else
            raise_malformed
          end
        when :mapping
          raise Puppet::DevError, "Debian interfaces mapping parsing not implemented."
        when :none
          raise_malformed
        end
      end
    end

    Instance.all_instances.map {|name, instance| instance.to_hash }
  end

  # Generate an array of sections
  def self.format_file(filename, providers)
    contents = []
    contents << header

    # Add onboot interfaces
    auto_interfaces = providers.select {|provider| provider.onboot == true }
    unless (auto_interfaces.empty?)
      stanza = []
      stanza << "auto " + auto_interfaces.map(&:name).sort.join(" ")
      contents << stanza.join("\n")
    end

    # Add hotpluggable interfaces
    hotplug_interfaces = providers.select {|provider| provider.hotplug == true }
    unless (hotplug_interfaces.empty?)
      stanza = []
      stanza << "allow-hotplug " + hotplug_interfaces.map(&:name).sort.join(" ")
      contents << stanza.join("\n")
    end

    # Build iface stanzas
    providers.sort_by(&:name).each do |provider|
      # TODO add validation method
      raise Puppet::Error, "#{provider.name} does not have a method." if provider.method.nil?
      raise Puppet::Error, "#{provider.name} does not have a family." if provider.family.nil?

      stanza = []
      stanza << %{iface #{provider.name} #{provider.family} #{provider.method}}

      [
        [:ipaddress, 'address'],
        [:netmask,   'netmask'],
        [:mtu,       'mtu'],
      ].each do |(property, section)|
        stanza << "#{section} #{provider.send property}" if provider.send(property) and provider.send(property) != :absent
      end

      if provider.mode == :vlan
          if provider.options["vlan-raw-device"]
            stanza << "vlan-raw-device #{provider.options["vlan-raw-device"]}"
          else
            vlan_range_regex = %r[\d{1,3}|40[0-9][0-5]]
            if ! provider.name.match(%r[\A([a-z]+\d+)(?::\d+|\.#{vlan_range_regex})\Z])          
              raise Puppet::Error, "Interface #{provider.name}: missing vlan-raw-device or wrong VLAN ID in the iface name"
            end
          end                 
      end      

      if provider.options and provider.options != :absent
        provider.options.each_pair do |key, val|
          if val.is_a? String
            # dont print property because we've already added it to the stanza
            if key != "vlan-raw-device"
              stanza << "    #{key} #{val}"
            end
          elsif val.is_a? Array
            val.each { |entry| stanza << "    #{key} #{entry}" }
          else
            raise Puppet::Error, "#{self} options key #{key} expects a String or Array, got #{val.class}"
          end
        end
      end

      contents << stanza.join("\n")
    end

    contents.map {|line| line + "\n\n"}.join
  end

  def self.header
    str = <<-HEADER
# HEADER: This file is is being managed by puppet. Changes to
# HEADER: interfaces that are not being managed by puppet will persist;
# HEADER: however changes to interfaces that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
    str
  end
end
