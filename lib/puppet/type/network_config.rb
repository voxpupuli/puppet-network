Puppet::Type.newtype(:network_config) do
  @doc = "Manage non-volatile network configuration information"

  ensurable

  newparam(:name) do
    desc "The name of the physical or logical network device"
  end

  newproperty(:attributes) do
    desc "Provider specific attributes to be passed to the provider"

    def retrieve
      provider.attributes
    end

    defaultto {}

    validate do |value|
      raise ArgumentError, "#{self.class} requires a hash for the options property" unless value.is_a? Hash
      #provider.validate
    end
  end
end
