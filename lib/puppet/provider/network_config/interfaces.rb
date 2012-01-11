# = Debian network_config provider
#
# This provider performs all real operations at the prefetch and flush stages
# of a puppet transaction, so the create, exists?, and destroy methods merely
# update the state that the resources should be in upon flushing.
require 'puppet/util/filetype'

Puppet::Type.type(:network_config).provide(:debian, :parent => Puppet::Provider) do

  desc "Debian /etc/network/interfaces provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

  def create
    @property_hash[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] and @property_hash[:ensure] == :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  # Delegate flush functionality to the class
  def flush
    self.class.flush
  end

  attr_accessor :attributes

  ##############################################################################
  # Class methods
  #
  # The following methods serve to generate all resources of this type, and then
  # flush all changes to disk. Generally, instance methods will either only
  # update their internal state or delegate their functionality to the class.
  ##############################################################################

  def self.initvars
    @file_path = "/etc/network/interfaces"
    @filetype  = Puppet::Util::FileType.filetype(:flat).new(@file_path)
    @interfaces = {}
  end

  self.initvars

  def self.instances
    read_interfaces

    @interfaces.reduce([]) do |arr, (interface, attributes)|
      instance = new(:name => interface, :ensure => :present, :provider => :debian)
      instance.attributes = attributes
      arr << instance
      arr
    end
  end

  private

  def self.iface_property(iface, name, value)
    @interfaces[iface] ||= {}
    @interfaces[iface][name] = value
  end

  # Debian has a very irregular format for the interfaces file. The
  # read_interfaces method is somewhat derived from the ifup executable
  # supplied in the debian ifupdown package. The source can be found at
  # http://packages.debian.org/squeeze/ifupdown
  def self.read_interfaces

    malformed_err_str = "Malformed debian interfaces file; cannot instantiate network_config resources"

    # The debian interfaces implementation requires global state while parsing
    # the file; namely, the stanza being parsed as well as the interface being
    # parsed.
    status = :none
    current_interface = nil

    lines = @filetype.read.split("\n")
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
      when /^auto/

        interfaces = line.split(' ')
        property = interfaces.delete_at(0).intern
        interfaces.each {|int| iface_property int, property, true}

        # Reset the current parse state
        current_interface = nil

      when /^allow-/

        interfaces = line.split(' ')
        property = interfaces.delete_at(0).intern
        interfaces.each {|int| iface_property int, property, true}

        # Reset the current parse state
        current_interface = nil

      when /^iface/

        # Format of the iface line:
        #
        # iface <iface> <proto> <method>
        # zero or more options for <iface>

        if line =~ /^iface (\S+)\s+(\S+)\s+(\S+)/
          iface  = $1
          proto  = $2
          method = $3

          status = :iface
          current_interface = iface

          iface_property($1, :proto,  $2)
          iface_property($1, :method, $3)
        else
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
          if line =~ /(\S+)\s+(.*)/
            iface_property current_interface, $1, $2
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
  end

  def self.header
    str = <<-HEADER
# HEADER: /etc/network/interfaces is being managed by puppet. Changes to
# HEADER: interfaces that are not being managed by puppet will persist;
# HEADER: however changes to interfaces that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
    str
  end
end
