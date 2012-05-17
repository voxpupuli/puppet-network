# This defines a mixin that provides for mapping an entire file to a set of
# puppet providers.
#
# Including classes should define the self.parse_file and self.format_resources
# methods.
require 'puppet'
require 'puppet/util'
require 'puppet/util/filetype'

module Puppet::Provider::Isomorphism

  def create
    # This was ripped off from parsedfile
    @resource.class.validproperties.each do |property|
      if value = @resource.should(property)
        @property_hash[property] = value
      end
    end
    # XXX this is a hack. fix.
    @property_hash[:name] = @resource.name

    self.class.needs_flush = true
  end

  def exists?
    @property_hash[:ensure] and @property_hash[:ensure] == :present
  end

  def destroy
    @property_hash[:ensure] = :absent
    self.class.needs_flush = true
  end

  # Delegate flush functionality to the class
  def flush
    self.class.flush
  end

  def self.included(klass)
    klass.extend Puppet::Provider::Isomorphism::ClassMethods
    klass.mk_resource_methods
    klass.initvars
  end

  ##############################################################################
  # Class methods
  #
  # The following methods serve to generate all resources of this type, and then
  # flush all changes to disk. Generally, instance methods will either only
  # update their internal state or delegate their functionality to the class.
  ##############################################################################

  module ClassMethods
    attr_accessor :file_path, :needs_flush

    # Intercept all instantiations of providers, present or absent, so that we
    # can reference everything when we rebuild the interfaces file.
    def new(*args)
      obj = super
      @provider_instances << obj
      obj
    end

    # self.initvars is a hook upon instantiation of the provider. It's basically
    # the class level constructor
    def initvars
      @provider_instances = []
      @needs_flush = false
    end

    # Lazily generate the filetype
    def filetype
      raise "#{self.class} requires file_path to be set" unless @file_path
      @filetype ||= Puppet::Util::FileType.filetype(:flat).new(@file_path)
    end

    def instances
      interfaces = parse_file

      # Iterate over the hash provided by parse_file, and for each one
      # generate a new provider and copy in the properties. Put all of these
      # in an array and return that.
      providers = interfaces.reduce([]) do |arr, (provider_name, provider_attributes)|
        provider_args = {
          :name     => provider_name,
          :ensure   => :present,
          :provider => self.name,
        }

        provider_args.merge! provider_attributes

        arr << new(provider_args)
        arr
      end
      providers
    end

    # Pass over all provider instances, and see if there is a resource with the
    # same namevar as a provider instance. If such a resource exists, set the
    # provider field of that resource to the existing provider.
    def prefetch(resources = {})

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

    # Generate attr_accessors for the properties, and have them mark the file
    # as modified if an attr_writer is called.
    # This is basically ripped off from ParsedFile
    def mk_resource_methods
      [resource_type.validproperties, resource_type.parameters].flatten.each do |attr|
        attr = symbolize(attr)

        # Generate attr_reader
        define_method(attr) do
          if @property_hash[attr]
            @property_hash[attr]
          elsif defined? @resource
            @resource.should(attr)
          end
        end

        # Generate attr_writer
        define_method("#{attr}=") do |val|
          @property_hash[attr] = val
          self.class.needs_flush = true
        end
      end
    end

    def flush
      if needs_flush # Only flush the providers if something was out of sync
        providers = @provider_instances.select {|prov| prov.ensure == :present}
        lines = format_resources(providers)
        filetype.backup
        content = lines.join("\n\n")
        filetype.write(content)
      end
    end

    def header
      str = <<-HEADER
# HEADER: #{@file_path} is being managed by puppet. Changes to
# HEADER: interfaces that are not being managed by puppet will persist;
# HEADER: however changes to interfaces that are being managed by puppet will
# HEADER: be overwritten. In addition, file order is NOT guaranteed.
# HEADER: Last generated at: #{Time.now}
HEADER
      str
    end
  end
end
