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

  desc 'Debian interfaces style provider'

  confine :osfamily => :debian
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
      msg ||= 'Malformed debian interfaces file; cannot instantiate network_config resources'
      super
    end
  end

  def self.raise_malformed
    @failed = true
    fail MalformedInterfacesError
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

      @options = Hash.new { |hash, key| hash[key] = [] }
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

      h.each_with_object({}) do |(key, val), hash|
        hash[key] = val if val
      end
    end

    def squeeze_options
      @options.each_with_object({}) do |(key, value), hash|
        hash[key] = if value.size <= 1
                      value.pop
                    else
                      value
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
          obj = new(name)
          all_instances[name] = obj
        end

        obj
      end
    end
  end

  def self.parse_file(_filename, contents)
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
    # TODO: Join lines that end with a backslash

    # Iterate over all lines and determine what attributes they create
    lines.each do |line|
      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      case line
      when /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next

      when /^source|^source-directory/
        # ignore source|source-directory sections, it makes this provider basically useless
        # with Debian Jessie. Please refer to man 5 interfaces
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

        raise_malformed unless line.match(/^iface\s+(\S+)\s+(\S+)\s+(\S+)/) do |matched|
          name   = matched[1]
          family = matched[2]
          method = matched[3]

          # If an iface block for this interface has been seen, the file is
          # malformed.
          raise_malformed if Instance[name] && Instance[name].family

          status = :iface
          current_interface = name

          # This is done automatically
          # Instance[name].name   = name
          Instance[name].family = family
          Instance[name].method = method
          Instance[name].mode   = :raw
        end

      when /^mapping/
        # XXX dox
        status = :mapping
        fail Puppet::DevError, 'Debian interfaces mapping parsing not implemented.'

      else
        # We're currently examining a line that is within a mapping or iface
        # stanza, so we need to validate the line and add the options it
        # specifies to the known state of the interface.

        case status
        when :iface
          raise_malformed unless line.match(/(\S+)\s+(\S.*)/) do |matched|
            # If we're parsing an iface stanza, then we should receive a set of
            # lines that contain two or more space delimited strings. Append
            # them as options to the iface in an array.

            key = matched[1]
            val = matched[2]

            name = current_interface

            case key # rubocop:disable Metrics/BlockNesting
            when 'address' then         Instance[name].ipaddress    = val
            when 'netmask' then         Instance[name].netmask      = val
            when 'mtu' then             Instance[name].mtu          = val
            when 'vlan-raw-device' then Instance[name].mode         = :vlan
            else Instance[name].options[key] << val
            end
          end
        when :mapping
          fail Puppet::DevError, 'Debian interfaces mapping parsing not implemented.'
        when :none
          raise_malformed
        end
      end
    end
    Instance.all_instances.map { |_name, instance| instance.to_hash }
  end

  # Generate an array of sections
  def self.format_file(_filename, providers)
    contents = []
    contents << header

    # Add onboot interfaces
    auto_interfaces = providers.select { |provider| provider.onboot == true }
    unless auto_interfaces.empty?
      stanza = []
      stanza << 'auto ' + auto_interfaces.map(&:name).sort.join(' ')
      contents << stanza.join("\n")
    end

    # Add hotpluggable interfaces
    hotplug_interfaces = providers.select { |provider| provider.hotplug == true }
    unless hotplug_interfaces.empty?
      stanza = []
      stanza << 'allow-hotplug ' + hotplug_interfaces.map(&:name).sort.join(' ')
      contents << stanza.join("\n")
    end

    # Build iface stanzas
    providers.sort_by(&:name).each do |provider|
      # TODO: add validation method
      fail Puppet::Error, "#{provider.name} does not have a method." if provider.method.nil?
      fail Puppet::Error, "#{provider.name} does not have a family." if provider.family.nil?

      stanza = []
      stanza << %(iface #{provider.name} #{provider.family} #{provider.method})

      if provider.mode == :vlan
        # if this is a :vlan mode interface than the name of the
        # `vlan-raw-device` is implied by the `iface` name in the format
        # fooX.<vlan>

        # The valid vlan ID range is 0-4095; 4096 is out of range
        vlan_range_regex = /[1-3]?\d{1,3}|40[0-8]\d|409[0-5]/
        raw_device = provider.name.match(/\A([a-z]+\d+)(?::\d+|\.#{vlan_range_regex})?\Z/)[1]

        stanza << %(vlan-raw-device #{raw_device})
      end

      [
        [:ipaddress, 'address'],
        [:netmask,   'netmask'],
        [:mtu,       'mtu']
      ].each do |(property, section)|
        stanza << "#{section} #{provider.send property}" if provider.send(property) && provider.send(property) != :absent
      end

      if provider.options && provider.options != :absent
        provider.options.each_pair do |key, val|
          if val.is_a? String
            stanza << "    #{key} #{val}"
          elsif val.is_a? Array
            val.each { |entry| stanza << "    #{key} #{entry}" }
          else
            fail Puppet::Error, "#{self} options key #{key} expects a String or Array, got #{val.class}"
          end
        end
      end

      contents << stanza.join("\n")
    end

    contents.map { |line| line + "\n\n" }.join
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
