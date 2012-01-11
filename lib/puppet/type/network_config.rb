Puppet::Type.newtype(:network_config) do
  @doc = "Manage non-volatile network configuration information"

  ensurable

  newparam(:name) do
    desc "The name of the physical or logical network device"
  end

  # Many network configurations can take arbitrary parameters, so instead of
  # trying to list every single possible attribute, we accept a hash of
  # attributes and let providers do specific mapping of type attributes to
  # on-disk state.
  newproperty(:attributes) do
    desc "Provider specific attributes to be passed to the provider"

    def retrieve
      provider.attributes
    end

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
