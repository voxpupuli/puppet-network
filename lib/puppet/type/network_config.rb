require 'puppet/property/boolean'

Puppet::Type.newtype(:network_config) do
  @doc = "Manage non-volatile network configuration information"

  feature :provider_options, <<-EOD
    The provider can accept a hash of arbitrary options. The semantics of
    these options will depend on the provider.
  EOD

  feature :hotpluggable, 'The system can hotplug interfaces'

  feature :reconfigurable, <<-EOD
    The provider can update live interface configuration after the non-volatile
    network configuration is updated. This may entail a momentary network
    disruption as it may mean bringing down the interface for a short period.
  EOD

  ensurable

  newparam(:name) do
    isnamevar
    desc "The name of the physical or logical network device"
  end

  newproperty(:ipaddress) do
    desc "The IP address of the network interfaces"
  end

  newproperty(:netmask) do
    desc "The subnet mask to apply to the interface"
  end

  newproperty(:method) do
    desc "The method for determining an IP address for the interface"
    newvalues(:static, :manual, :dhcp, :loopback)

    # Redhat systems frequently use 'none' in place of 'static', although
    # ultimately any values but dhcp or bootp are ignored and the interface
    # is static
    aliasvalue(:none, :static)

    defaultto :dhcp
  end

  newproperty(:family) do
    desc "The address family to use for the interface"
    newvalues(:inet, :inet6)
    defaultto :inet
  end

  newproperty(:onboot, :parent => Puppet::Property::Boolean) do
    desc "Whether to bring the interface up on boot"
    defaultto :true
  end

  newproperty(:hotplug, :required_features => :hotpluggable, :parent => Puppet::Property::Boolean) do
    desc "Allow/disallow hotplug support for this interface"
    defaultto :true
  end

  newparam(:reconfigure, :required_features => :reconfigurable, :parent => Puppet::Property::Boolean) do
    desc "Reconfigure the interface after the configuration has been updated"
  end

  # `:options` provides an arbitrary passthrough for provider properties, so
  # that provider specific behavior doesn't clutter up the main type but still
  # allows for more powerful actions to be taken.
  newproperty(:options, :required_features => :provider_options) do
    desc "Provider specific options to be passed to the provider"

    def is_to_s(hash = @is)
      hash.keys.sort.map {|key| "#{key} => #{hash[key]}"}.join(", ")
    end

    def should_to_s(hash = @should)
      hash.keys.sort.map {|key| "#{key} => #{hash[key]}"}.join(", ")
    end

    defaultto {}

    validate do |value|
      raise ArgumentError, "#{self.class} requires a hash for the options property" unless value.is_a? Hash
      #provider.validate
    end
  end
end
