require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:redhat) do
  # Red Hat network_config network scripts provider.
  #
  # This provider manages the contents of /etc/networks-scripts/ifcfg-* to
  # manage non-volatile network configuration.
  #
  # @see https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html "Red Hat Interface Configuration Files"

  include PuppetX::FileMapper

  desc "Redhat network-scripts provider"

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  has_feature :hotpluggable
  has_feature :provider_options

  # @return [String] The path to network-script directory on redhat systems
  SCRIPT_DIRECTORY = "/etc/sysconfig/network-scripts"

  # The valid vlan ID range is 0-4095; 4096 is out of range
  VLAN_RANGE_REGEX = %r[\d{1,3}|40[0-9][0-5]]

  # @return [Regexp] The regular expression for interface scripts on redhat systems
  SCRIPT_REGEX     = %r[\Aifcfg-[a-z]+\d+(?::\d+|\.#{VLAN_RANGE_REGEX})?\Z]

  NAME_MAPPINGS = {
    :ipaddress  => 'IPADDR',
    :netmask    => 'NETMASK',
    :method     => 'BOOTPROTO',
    :onboot     => 'ONBOOT',
    :name       => 'DEVICE',
    :hotplug    => 'HOTPLUG',
    :mtu        => 'MTU',
  }

  # Map provider instances to files based on their name
  #
  # @return [String] The path of the file for the given interface resource
  #
  # @example
  #   prov = RedhatProvider.new(:name => 'eth1')
  #   prov.select_file # => '/etc/sysconfig/network-scripts/ifcfg-eth1'
  #
  def select_file
    "#{SCRIPT_DIRECTORY}/ifcfg-#{name}"
  end

  # Scan all files in the networking directory for interfaces
  #
  # @param script_dir [String] The path to the networking scripts, defaults to
  #   {#SCRIPT_DIRECTORY}
  #
  # @return [Array<String>] All network-script config files on this machine.
  #
  # @example
  #   RedhatProvider.target_files
  #   # => ['/etc/sysconfig/network-scripts/ifcfg-eth0', '/etc/sysconfig/network-scripts/ifcfg-eth1']
  def self.target_files(script_dir = SCRIPT_DIRECTORY)
    entries = Dir.entries(script_dir).select {|entry| entry.match SCRIPT_REGEX}
    entries.map {|entry| File.join(SCRIPT_DIRECTORY, entry)}
  end

  # Convert a redhat network script into a hash
  #
  # This is a hook method that will be called by PuppetX::Filemapper
  #
  # @param [String] filename The path of the interfaces file being parsed
  # @param [String] contents The contents of the given file
  #
  # @return [Array<Hash<Symbol, String>>] A single element array containing
  #   the key/value pairs of properties parsed from the file.
  #
  # @example
  #   RedhatProvider.parse_file('/etc/sysconfig/network-scripts/ifcfg-eth0', #<String:0xdeadbeef>)
  #   # => [
  #   #   {
  #   #     :name      => 'eth0',
  #   #     :ipaddress => '169.254.0.1',
  #   #     :netmask   => '255.255.0.0',
  #   #   },
  #   # ]
  def self.parse_file(filename, contents)
    # Remove/ignore functions when parsing
    function_regex = /^(function )?[\w()]+\s*{.*}/m
    contents.gsub!(function_regex, '')

    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(/#.*$/, '') }
    # Remove all blank lines
    lines.reject! { |line| line.match(/^\s*$/) }

    pair_regex = %r/^\s*(.+?)\s*=\s*(.*)\s*$/

    # Convert the data into key/value pairs
    pairs = lines.inject({}) do |hash, line|
      if (m = line.match pair_regex)
        key = m[1].strip
        val = m[2].strip
        hash[key] = val
      else
        raise Puppet::Error, %{#{filename} is malformed; "#{line}" did not match "#{pair_regex.to_s}"}
      end
      hash
    end

    props = self.munge(pairs)

    # TODO remove duct tape for #13
    #
    # The :family property is making less and less sense because it seems that
    # ipv6 configuration should add new properties instead of trying to collide
    # with the ipv4 addresses. But right now, the :inet property is never used
    # and it's creating a change on each resource update. This is a patch until
    # the :family property is ripped out.
    #
    # See https://github.com/adrienthebo/puppet-network/issues/13 for the full
    # issue that caused this, and https://github.com/adrienthebo/puppet-network/issues/16
    # for the resolution.
    #
    props.merge!({:family => :inet})

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [props]
  end

  # @api private
  def self.munge(pairs)
    props = {}

    # Unquote all values
    pairs.each_pair do |key, val|
      if (munged = val.gsub(/['"]/, ''))
        pairs[key] = munged
      end
    end

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    NAME_MAPPINGS.each_pair do |type_name, redhat_name|
      if (val = pairs[redhat_name])
        # We've recognized a value that maps to an actual type property, delete
        # it from the pairs and copy it as an actual property
        pairs.delete(redhat_name)
        props[type_name] = val
      end
    end

    # For all of the remaining values, blindly toss them into the options hash.
    props[:options] = pairs unless pairs.empty?

    [:onboot, :hotplug].each do |bool_property|
      if props[bool_property]
        props[bool_property] = (props[bool_property] == 'yes')
      end
    end

    unless ['bootp', 'dhcp'].include? props[:method]
      props[:method] = 'static'
    end

    props
  end

  def self.format_file(filename, providers)
    if providers.length == 0
      return ""
    elsif providers.length > 1
      raise Puppet::DevError, "Unable to support multiple interfaces [#{providers.map(&:name).join(',')}] in a single file #{filename}"
    end

    provider = providers[0]
    props    = {}

    # Map everything to a flat hash
    props = (provider.options || {})

    NAME_MAPPINGS.keys.each do |type_name|
      if (val = provider.send(type_name))
        props[type_name] = val
      end
    end

    pairs = self.unmunge props

    content = pairs.inject('') do |str, (key, val)|
      str << %{#{key}=#{val}\n}
    end

    content
  end

  def self.unmunge(props)

    pairs = {}

    [:onboot, :hotplug].each do |bool_property|
      if props[bool_property]
        props[bool_property] = ((props[bool_property] == true) ? 'yes' : 'no')
      end
    end

    NAME_MAPPINGS.each_pair do |type_name, redhat_name|
      if (val = props[type_name])
        props.delete(type_name)
        pairs[redhat_name] = val
      end
    end

    pairs.merge! props

    pairs.each_pair do |key, val|
      if val.is_a? String and val.match /\s+/
        pairs[key] = %{"#{val}"}
      end
    end

    pairs
  end

  def self.post_flush_hook(filename)
    File.chmod(0644, filename)
  end
end
