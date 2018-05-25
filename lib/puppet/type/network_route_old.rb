require 'ipaddr'
require_relative '../../puppet_x/voxpupuli/utils.rb'

Puppet::Type.newtype(:network_route) do
  @doc = 'Manage non-volatile route configuration information'

  include PuppetX::Voxpupuli::Utils

  ensurable

  newparam(:name) do
    isnamevar
    desc 'The name of the network route'
  end

  newproperty(:network) do
    isrequired
    desc 'The target network address'
    validate do |value|
      unless value == 'default'
        a = PuppetX::Voxpupuli::Utils.try { IPAddr.new(value) }
        raise("Invalid value for network: #{value}") unless a
      end
    end
  end

  newproperty(:netmask) do
    isrequired
    desc 'The subnet mask to apply to the route'

    validate do |value|
      unless value.length <= 3 || PuppetX::Voxpupuli::Utils.try { IPAddr.new(value) }
        raise("Invalid value for argument netmask: #{value}")
      end
    end

    munge do |value|
      # '255.255.255.255'.to_i  will return 255, so we try to convert it back:
      if value.to_i.to_s == value
        # what are the chances someone is using /16 for their IPv6 network?
        addr = value.to_i <= 32 ? '255.255.255.255' : 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'
        IPAddr.new(addr).mask(value.strip.to_i).to_s
      elsif PuppetX::Voxpupuli::Utils.try { IPAddr.new(value).ipv6? }
        IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff').mask(value).to_s
      elsif PuppetX::Voxpupuli::Utils.try { IPAddr.new(value).ipv4? }
        IPAddr.new('255.255.255.255').mask(value).to_s
      else
        raise("Invalid value for argument netmask: #{value}")
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
