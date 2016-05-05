require 'ipaddr'

Puppet::Type.newtype(:network_route) do
  @doc = 'Manage non-volatile route configuration information'

  ensurable

  newparam(:name) do
    isnamevar
    desc 'The name of the network route'
  end

  newproperty(:network) do
    isrequired
    desc 'The target network address'
    validate do |value|
      begin
        IPAddr.new(value) unless value == 'default'
      rescue
        raise("Invalid value for network: #{value}")
      end
    end
  end

  newproperty(:netmask) do
    isrequired
    desc 'The subnet mask to apply to the route'

    validate do |value|
      unless value.length <= 3 || (IPAddr.new(value) rescue false)
        raise("Invalid value for argument netmask: #{value}")
      end
    end

    munge do |value|
      # '255.255.255.255'.to_i  will return 255, so we try to convert it back:
      if value.to_i.to_s == value
        if value.to_i <= 32
          IPAddr.new('255.255.255.255').mask(value.strip.to_i).to_s
        else
          IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff').mask(value.strip.to_i).to_s
        end
      else
        if (IPAddr.new(value).ipv6? rescue false)
          IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff').mask(value).to_s
        elsif (IPAddr.new(value).ipv4? rescue false)
          IPAddr.new('255.255.255.255').mask(value).to_s
        else
          raise("Invalid value for argument netmask: #{value}")
        end
      end
    end
  end

  newproperty(:gateway) do
    isrequired
    desc 'The gateway to use for the route'

    validate do |value|
      begin
        IPAddr.new(value)
      rescue ArgumentError
        raise("Invalid value for gateway: #{value}")
      end
    end
  end

  newproperty(:interface) do
    isrequired
    desc 'The interface to use for the route'
  end

  # `:options` provides an arbitrary passthrough for provider properties, so
  # that provider specific behavior doesn't clutter up the main type but still
  # allows for more powerful actions to be taken.
  newproperty(:options, required_features: :provider_options) do
    desc 'Provider specific options to be passed to the provider'

    validate do |value|
      raise ArgumentError, "#{self.class} requires a string for the options property" unless value.is_a?(String)
    end
  end
end
