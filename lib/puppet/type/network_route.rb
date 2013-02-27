require 'ipaddr'

Puppet::Type.newtype(:network_route) do
  @doc = "Manage non-volatile route configuration information"

  ensurable

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
      unless (value.length <= 2 or value =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/) # yikes
        fail("Invalid value for argument netmask: #{value}")
      end
    end

    munge do |value|
      r = IPAddr.new('255.255.255.255').mask(value.strip.to_i).to_s
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
end
