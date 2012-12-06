require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:interfaces) do
  # Debian network_config interfaces provider.
  #
  # This provider uses the filemapper mixin to map the interfaces file to a
  # collection of network_config providers, and back.
  #
  # @see http://wiki.debian.org/NetworkConfiguration

  include PuppetX::FileMapper

  desc "Debian interfaces style provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

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

    # Build out an empty hash for new interfaces for storing their configs.
    iface_hash = Hash.new do |hash, key|
      hash[key] = {}
      hash[key][:name] = key

      # example
      #   {
      #     :"pre-up" => ['command one', 'command two'],
      #     :down     => ['command three', 'command four'],
      #   }
      #
      # XXX This is getting very complex. This should be broken down.
      hash[key][:options] = Hash.new {|hash, key| hash[key] = []}

      hash[key]
    end

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

        interfaces.each do |iface|
          iface_hash[iface][:onboot]  = :true
        end

        # Reset the current parse state
        current_interface = nil

      when /^allow-hotplug/
        # parse out allow-hotplug lines

        interfaces = line.split(' ')
        interfaces.delete_at(0)

        interfaces.each do |iface|
          iface_hash[iface][:hotplug] = :true
        end

        # Don't reset Reset the current parse state
      when /^iface/

        # Format of the iface line:
        #
        # iface <iface> <family> <method>
        # zero or more options for <iface>

        if match = line.match(/^iface (\S+)\s+(\S+)\s+(\S+)/)
          iface  = match[1]
          family = match[2]
          method = match[3]

          status = :iface
          current_interface = iface

          # If an iface block for this interface has been seen, the file is
          # malformed.
          if iface_hash[iface] and iface_hash[iface][:family]
            raise_malformed
          end

          iface_hash[iface][:family] = family
          iface_hash[iface][:method] = method
          iface_hash[iface][:name]    = iface

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

            iface = current_interface

            case key
            when 'address'; iface_hash[iface][:ipaddress] = val
            when 'netmask'; iface_hash[iface][:netmask] = val
            else iface_hash[iface][:options][key] = val
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
    iface_hash.values
  end

  # Generate an array of sections
  def self.format_file(filename, providers)
    contents = []
    contents << header

    # Add onboot interfaces
    if (auto_interfaces = providers.select {|provider| provider.onboot == :true })
      stanza = []
      stanza << "# The following interfaces will be started on boot"
      stanza << "auto " + auto_interfaces.map(&:name).sort.join(" ")
      contents << stanza.join("\n")
    end

    # Add hotpluggable interfaces
    if (hotplug_interfaces = providers.select {|provider| provider.hotplug == :true })
      stanza = []
      stanza << "# The following interfaces are hotpluggable"
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

      {
        :ipaddress => 'address',
        :netmask   => 'netmask',
      }.each_pair do |property, section|
        stanza << "#{section} #{provider.send property}" if provider.send(property)
      end

      if provider.options
        provider.options.each_pair do |key, val|
          stanza << "#{key} #{val}"
        end
      end

      contents << stanza.join("\n")
    end

    # Given a series of stanzas,
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
