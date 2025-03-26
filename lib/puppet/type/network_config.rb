require 'puppet/property/boolean'

begin
  require 'ipaddr'
rescue LoadError
  Puppet.warning("#{__FILE__}:#{__LINE__}: ipaddr gem was not found")
end

Puppet::Type.newtype(:network_config) do
  @doc = 'Manage non-volatile network configuration information'

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

  feature :startmode, 'The system can define startmode of an interface'

  ensurable

  newparam(:name) do
    isnamevar
    desc 'The name of the physical or logical network device'
  end

  newproperty(:ipaddress) do
    desc 'The IP address of the network interfaces'
    if defined? IPAddr
      validate do |value|
        IPAddr.new value
      rescue IPAddr::InvalidAddressError
        raise ArgumentError, "#{self.class} requires a valid ipaddress for the ipaddress property"
        # provider.validate
      end
    end
  end

  newproperty(:netmask) do
    desc 'The subnet mask to apply to the interface'
    if defined? IPAddr
      validate do |value|
        ipa = IPAddr.new '127.0.0.1'
        ipa.mask(value)
      rescue IPAddr::InvalidAddressError
        begin
          ipz = IPAddr.new '::1'
          ipz.mask(value)
        rescue IPAddr::InvalidAddressError
          raise ArgumentError, "#{self.class} requires a valid netmask for the netmask property"
        end
        # provider.validate
      end
    end
  end

  newproperty(:method) do
    desc 'The method for determining an IP address for the interface'
    newvalues(:static, :manual, :dhcp, :loopback)

    # Redhat systems frequently use 'none' in place of 'static', although
    # ultimately any values but dhcp or bootp are ignored and the interface
    # is static
    aliasvalue(:none, :static)

    defaultto :dhcp
  end

  newproperty(:family) do
    desc 'The address family to use for the interface'
    newvalues(:inet, :inet6)
    aliasvalue(:inet4, :inet)
    defaultto :inet
  end

  newproperty(:onboot, parent: Puppet::Property::Boolean) do
    desc 'Whether to bring the interface up on boot'
    defaultto :true
  end

  newproperty(:hotplug, required_features: :hotpluggable, parent: Puppet::Property::Boolean) do
    desc 'Allow/disallow hotplug support for this interface'
    defaultto :true
  end

  newproperty(:startmode, required_features: :startmode) do
    desc 'Allow/disallow startmode support for this interface'
    defaultto :auto
  end

  newparam(:reconfigure, required_features: :reconfigurable, parent: Puppet::Property::Boolean) do
    desc 'Reconfigure the interface after the configuration has been updated'
  end

  newparam(:order_rules) do
    desc 'Specify order rules of interfaces'
  end

  newproperty(:mtu) do
    desc 'The Maximum Transmission Unit size to use for the interface'
    validate do |value|
      # reject floating point and negative integers
      # XXX this lets 1500.0 pass
      if value.is_a? Numeric
        raise ArgumentError, "#{value} is not a valid mtu (must be a positive integer)" unless value.integer?
      else
        raise ArgumentError, "#{value} is not a valid mtu (must be a positive integer)" unless value =~ %r{^\d+$}
      end

      # Intel 82598 & 82599 chips support MTUs up to 16110; is there any
      # hardware in the wild that supports larger frames?
      #
      # It appears loopback devices routinely have large MTU values; Eg. 65536
      #
      # Frames small than 64bytes are discarded as runts.  Smallest valid MTU
      # is 42 with a 802.1q header and 46 without.
      min_mtu = 42
      max_mtu = 65_536
      raise ArgumentError, "#{value} is not in the valid mtu range (#{min_mtu} .. #{max_mtu})" unless (min_mtu..max_mtu).cover?(value.to_i)
    end
  end

  newproperty(:mode) do
    desc 'The exclusive mode the interface should operate in'
    # :bond and :bridge may be added in the future
    newvalues(:raw, :vlan)

    defaultto :raw
  end

  # `:options` provides an arbitrary passthrough for provider properties, so
  # that provider specific behavior doesn't clutter up the main type but still
  # allows for more powerful actions to be taken.
  newproperty(:options, required_features: :provider_options) do
    desc 'Provider specific options to be passed to the provider'

    def s?(hash = @is)
      hash.keys.sort.map { |key| "#{key} => #{hash[key]}" }.join(', ')
    end

    def should_to_s(hash = @should)
      hash.keys.sort.map { |key| "#{key} => #{hash[key]}" }.join(', ')
    end

    defaultto {}

    validate do |value|
      raise ArgumentError, "#{self.class} requires a hash for the 'options' parameter" unless value.is_a? Hash
      # provider.validate
    end
  end
end
