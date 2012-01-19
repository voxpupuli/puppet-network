# = Debian network_config provider
#
# This provider performs all real operations at the prefetch and flush stages
# of a puppet transaction, so the create, exists?, and destroy methods merely
# update the state that the resources should be in upon flushing.
require 'puppet/util/filetype'

Puppet::Type.type(:network_config).provide(:interfaces, :parent => Puppet::Provider) do

  desc "Debian /etc/network/interfaces provider"

  confine    :osfamily => :debian
  defaultfor :osfamily => :debian

  def create
    @property_hash[:ensure] = :present
    # If we're creating a new resource, assume reasonable defaults.
    @property_hash[:attributes] = {:iface => {:proto => "inet", :method => "dhcp"}, :auto => true}
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

  def attributes
    @property_hash[:attributes] ||= {}
  end

  def attributes=(attrs)
    @property_hash[:attributes] = attrs
  end

  ##############################################################################
  # Class methods
  #
  # The following methods serve to generate all resources of this type, and then
  # flush all changes to disk. Generally, instance methods will either only
  # update their internal state or delegate their functionality to the class.
  ##############################################################################

  class << self
    # XXX should these instance variables really be exposed?
    attr_reader :file_path, :filetype
  end

  def self.initvars
    @file_path = "/etc/network/interfaces"
    @filetype  = Puppet::Util::FileType.filetype(:flat).new(@file_path)
  end

  initvars

  mk_resource_methods # Instantiate accessors for resource properties

  def self.instances
    interfaces = read_interfaces

    providers = interfaces.reduce([]) do |arr, (interface, attributes)|
      instance = new(:name => interface.to_s, :ensure => :present, :provider => :interfaces)
      instance.attributes = attributes
      arr << instance
      arr
    end
    providers
  end

  # Pass over all provider instances, and see if there is a resource with the
  # same namevar as a provider instance. If such a resource exists, set the
  # provider field of that resource to the existing provider.
  def self.prefetch(resources = {})

    # generate hash of {provider_name => provider}
    providers = instances.inject({}) do |hash, instance|
      hash[instance.name] = instance
      hash
    end

    # For each prefetched resource, try to match it to a provider
    resources.each do |resource_name, resource|
      if provider = providers[resource_name]
        resource.provider = provider
      end
    end

    # Generate default providers for resources that don't exist on disk
    resources.values.select {|resource| resource.provider.nil? }.each do |resource|
      resource.provider = new(:name => resource.name, :provider => :interfaces, :ensure => :absent)
    end
  end

  # Intercept all instantiations of providers, present or absent, so that we
  # can reference everything when we rebuild the interfaces file.
  def self.new(*args)
    obj = super
    @provider_instances ||= []
    @provider_instances << obj
    obj
  end

  def self.read_interfaces
    # Debian has a very irregular format for the interfaces file. The
    # read_interfaces method is somewhat derived from the ifup executable
    # supplied in the debian ifupdown package. The source can be found at
    # http://packages.debian.org/squeeze/ifupdown

    malformed_err_str = "Malformed debian interfaces file; cannot instantiate network_config resources"

    # The debian interfaces implementation requires global state while parsing
    # the file; namely, the stanza being parsed as well as the interface being
    # parsed.
    status = :none
    current_interface = nil
    iface_hash = {}

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

      when /^allow-|^auto/

        # parse out allow-* and auto stanzas.

        interfaces = line.split(' ')
        property = interfaces.delete_at(0).intern

        interfaces.each do |iface|
          iface = iface
          iface_hash[iface] ||= {}
          iface_hash[iface][property] = true
        end

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

          # If an iface block for this interface has been seen, the file is
          # malformed.
          if iface_hash[iface] and iface_hash[iface][:iface]
            raise Puppet::Error, malformed_err_str
          end

          iface_hash[iface] ||= {}
          iface_hash[iface][:iface] = {"proto" => proto, "method" => method}

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
          if line =~ /(\S+)\s+(.*)/
            iface_hash[current_interface][:iface].merge!($1 => $2)
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

  def self.flush
    providers = @provider_instances

    if true # Only flush the providers if something was out of sync

      # Delete any providers that should be absent
      providers.reject! {|provider| provider.ensure == :absent}

      @filetype.backup
      write_interfaces(providers)
    end
  end

  # TODO split out flush method and method to write file.
  def self.write_interfaces(providers)
    contents = []
    contents << header

    # Determine auto and hotplug interfaces and add them, if any
    [:auto, :"allow-auto", :"allow-hotplug"].each do |attr|
      interfaces = providers.select { |provider| provider.attributes[attr] }
      contents << "#{attr} #{interfaces.map {|i| i.name}.join(" ")}" unless interfaces.empty?
    end

    # Build up iface blocks
    iface_interfaces = providers.select { |provider| provider.attributes[:iface] }
    iface_interfaces.each do |provider|
      attributes = provider.attributes.dup
      block = []
      if attributes[:iface]

        # Build up iface line, by deleting the attributes from that interface
        # that are header specific. For everything else, it's an additional
        # option to the iface block, so add it following the iface line.
        block << "iface #{provider.name} #{attributes[:iface].delete("proto")} #{attributes[:iface].delete("method")}"
        attributes[:iface].each_pair do |key, val|
          block << "#{key} #{val}"
        end
      end
      contents << block.join("\n")
    end

    @filetype.write contents.join("\n\n")
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
