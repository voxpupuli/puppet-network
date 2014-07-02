require 'ipaddr'

Puppet::Type.newtype(:network_route) do
  @doc = "Manage non-volatile route configuration information"

  ensurable

  IPV4_ADDRESS_REGEX = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/

  newparam(:name) do
    isnamevar
    desc "The name of the network route"
  end

  newproperty(:network) do
    isrequired
    desc "The target network address"
    validate do |value|
      begin
        t = IPAddr.new(value) unless value == "default"
      rescue ArgumentError
        fail("Invalid value for network: #{value}")
      end
    end
  end

  newproperty(:netmask) do
    isrequired
    desc "The subnet mask to apply to the route"

    validate do |value|
      unless (value.length <= 2 or value =~ IPV4_ADDRESS_REGEX)
        fail("Invalid value for argument netmask: #{value}")
      end
    end

    munge do |value|
      case value
      when IPV4_ADDRESS_REGEX
        value
      when /^\d+$/
        IPAddr.new('255.255.255.255').mask(value.strip.to_i).to_s
      end
    end
  end

  newproperty(:gateway) do
    isrequired
    desc "The gateway to use for the route"

    validate do |value|
      begin
        t = IPAddr.new(value)
      rescue ArgumentError
        fail("Invalid value for gateway: #{value}")
      end
    end
  end

  newproperty(:interface) do
    isrequired
    desc "The interface to use for the route"
  end

  # `:options` provides an arbitrary passthrough for provider properties, so
  # that provider specific behavior doesn't clutter up the main type but still
  # allows for more powerful actions to be taken.
  newproperty(:options, :required_features => :provider_options) do
    desc "Provider specific options to be passed to the provider"

    validate do |value|
      raise ArgumentError, "#{self.class} requires a string for the options property" unless value.is_a?(String)
    end
  end
end
