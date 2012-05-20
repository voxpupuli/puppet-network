# = Debian network_config provider
#
# This provider uses the isomorphism mixin to map the interfaces file to a
# collection of network_config providers, and back.
require 'puppet/provider/isomorphism'

Puppet::Type.type(:network_config).provide(:interfaces) do

  include Puppet::Provider::Isomorphism
  self.file_path = '/etc/network/interfaces'

  desc "Debian interfaces style provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

  def self.parse_file
    # Debian has a very irregular format for the interfaces file. The
    # parse_file method is somewhat derived from the ifup executable
    # supplied in the debian ifupdown package. The source can be found at
    # http://packages.debian.org/squeeze/ifupdown

    malformed_err_str = "Malformed debian interfaces file; cannot instantiate network_config resources"

    # The debian interfaces implementation requires global state while parsing
    # the file; namely, the stanza being parsed as well as the interface being
    # parsed.
    status = :none
    current_interface = nil
    iface_hash = {}

    lines = filetype.read.split("\n")
    # TODO line munging
    # Join lines that end with a backslash
    # Strip comments?

    # Iterate over all lines and determine what attributes they create
    lines.each do |line|

      # Strip off any trailing comments
      line.sub!(/#.*$/, '')

      case line
      when /^\s*#|^\s*$/
        # Ignore comments and blank lines
        next

      when /^allow-auto|^auto/

        # parse out allow-auto and auto stanzas.

        interfaces = line.split(' ')
        interfaces.delete_at(0)

        interfaces.each do |iface|
          iface_hash[iface] ||= {}
          iface_hash[iface][:options] ||= {}
          iface_hash[iface][:onboot] = true
        end

        # Reset the current parse state
        current_interface = nil

      when /^allow-hotplug/

        # parse out allow-hotplug lines

        interfaces = line.split(' ')
        interfaces.delete_at(0)

        interfaces.each do |iface|
          iface_hash[iface] ||= {}
          iface_hash[iface][:options] ||= {}
          iface_hash[iface][:options][:"allow-hotplug"] = true
        end

        # Reset the current parse state
        current_interface = nil

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
            raise Puppet::Error, malformed_err_str
          end

          iface_hash[iface] ||= {}
          iface_hash[iface][:family] = family
          iface_hash[iface][:method] = method
          iface_hash[iface][:options] ||= {}

        else
          # If we match on a string with a leading iface, but it isn't in the
          # expected format, malformed blar blar
          raise Puppet::Error, malformed_err_str
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

            # TODO split this out

            key = match[1]
            val = match[2]

            iface = current_interface

            case key
            when 'address'; iface_hash[iface][:ipaddress] = val
            when 'netmask'; iface_hash[iface][:netmask] = val
            else iface_hash[iface][:options][key] = val
            end
          else
            raise Puppet::Error, malformed_err_str
          end
        when :mapping
          raise Puppet::DevError, "Debian interfaces mapping parsing not implemented."
        when :none
          raise Puppet::Error, malformed_err_str
        end
      end
    end
    iface_hash
  end

  # Generate an array of arrays
  def self.format_resources(providers)
    contents = []
    contents << header

    # Add onboot interfaces
    if auto_interfaces = providers.select(&:onboot)
      contents << "auto " + auto_interfaces.map {|iface| iface.property(:name)}.sort.join(" ")
    end

    # Determine auto and hotplug interfaces and add them, if any
    [:"allow-auto", :"allow-hotplug"].each do |attr|
      interfaces = providers.select { |provider| provider.options and provider.options[attr] }
      contents << "#{attr} #{interfaces.map {|i| i.name}.sort.join(" ")}" unless interfaces.empty?
    end

    # Build iface stanzas
    providers.sort_by(&:name).each do |provider|
      # TODO add validation method
      if provider.method.nil?
        raise Puppet::Error, "#{provider.name} does not have a method."
      end

      if provider.family.nil?
        raise Puppet::Error, "#{provider.name} does not have a family."
      end

      stanza = []
      stanza << %{iface #{provider.name} #{provider.family} #{provider.method}}

      if provider.options
        provider.options.each_pair do |key, val|
          stanza << "#{key} #{val}"
        end
      end

      contents << stanza.join("\n")
    end
  end
end
