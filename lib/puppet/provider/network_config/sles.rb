require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:sles) do
  # SLES network_config network scripts provider.
  #
  # This provider manages the contents of /etc/networks/ifcfg-* to
  # manage non-volatile network configuration.
  #
  # @see https://documentation.suse.com/sles/15-SP1/html/SLES-all/cha-network.html#sec-network-manconf-files-ifcfg

  include PuppetX::FileMapper

  desc 'SLES network-scripts provider'

  confine osfamily: :suse
  defaultfor osfamily: :suse

  has_feature :startmode
  has_feature :provider_options

  # @return [String] The path to network-script directory on sles systems
  SLES_SCRIPT_DIRECTORY = '/etc/sysconfig/network'.freeze # rubocop:disable Lint/ConstantDefinitionInBlock

  # The valid vlan ID range is 0-4095; 4096 is out of range
  SLES_VLAN_RANGE_REGEX = %r{[1-3]?\d{1,3}|40[0-8]\d|409[0-5]}.freeze # rubocop:disable Lint/ConstantDefinitionInBlock

  # aliases are almost free game, sles rejects some, and max total length is 15 characters
  # 15 minus at least 2 for the interface name, and a colon leaves 12 characters for the alias
  SLES_ALIAS_REGEX = %r{.{1,12}(?<!~|\.bak|\.old|\.orig|\.rpmnew|\.rpmorig|\.rpmsave|\.scpmbackup)}.freeze # rubocop:disable Lint/ConstantDefinitionInBlock

  # @return [Regexp] The regular expression for interface scripts on sles systems
  SLES_SCRIPT_REGEX = %r{\Aifcfg-[a-z]+[a-z\d]+(?::#{SLES_ALIAS_REGEX}|\.#{SLES_VLAN_RANGE_REGEX})?\Z}.freeze # rubocop:disable Lint/ConstantDefinitionInBlock

  # rubocop:disable Lint/ConstantDefinitionInBlock
  SLES_NAME_MAPPINGS = {
    ipaddress: 'IPADDR',
    netmask: 'NETMASK',
    method: 'BOOTPROTO',
    mtu: 'MTU',
    startmode: 'STARTMODE',
  }.freeze
  # rubocop:enable Lint/ConstantDefinitionInBlock

  # Map provider instances to files based on their name
  #
  # @return [String] The path of the file for the given interface resource
  #
  # @example
  #   prov = SLESProvider.new(:name => 'eth1')
  #   prov.select_file # => '/etc/sysconfig/network/ifcfg-eth1'
  #
  def select_file
    "#{SLES_SCRIPT_DIRECTORY}/ifcfg-#{name}"
  end

  # Scan all files in the networking directory for interfaces
  #
  # @param script_dir [String] The path to the networking scripts, defaults to
  #   {#SLES_SCRIPT_DIRECTORY}
  #
  # @return [Array<String>] All network-script config files on this machine.
  #
  # @example
  #   SLESProvider.target_files
  #   # => ['/etc/sysconfig/network/ifcfg-eth0', '/etc/sysconfig/network/ifcfg-eth1']
  def self.target_files(script_dir = SLES_SCRIPT_DIRECTORY)
    entries = Dir.entries(script_dir).select { |entry| entry.match SCRIPT_REGEX }
    entries.map { |entry| File.join(SLES_SCRIPT_DIRECTORY, entry) }
  end

  # Convert a SLES network script into a hash
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
  #   SLESProvider.parse_file('/etc/sysconfig/network/ifcfg-eth0', #<String:0xdeadbeef>)
  #   # => [
  #   #   {
  #   #     :name      => 'eth0',
  #   #     :ipaddress => '169.254.0.1',
  #   #     :netmask   => '255.255.0.0',
  #   #   },
  #   # ]
  def self.parse_file(filename, contents)
    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(%r{#.*$}, '') }
    # Remove all blank lines
    lines.reject! { |line| line =~ %r{^\s*$} }

    pair_regex = %r{^\s*(.+?)\s*=\s*(.*)\s*$}

    # INFO: It is valid ifcfg format to include certain functions and strings these should not be reported as errors, but silently removed before parsing
    # https://bugs.centos.org/bug_view_page.php?bug_id=475
    # Remove lines with no = sign
    lines.select! { |line| line =~ %r{^.*=.*$} }

    # Convert the data into key/value pairs
    pairs = lines.each_with_object({}) do |line, hash|
      raise Puppet::Error, %(#{filename} is malformed; "#{line}" did not match "#{pair_regex}") unless line.match(pair_regex) do |m|
        key = m[1].strip
        val = m[2].strip
        hash[key] = val
      end

      hash
    end

    props = munge(pairs)

    # TODO: remove duct tape for #13
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
    props[:family] = :inet

    # If there is no DEVICE property in the interface configuration we retrieve
    # the interface name from the file name itself
    props[:name] = filename.split('ifcfg-')[1] unless props.key?(:name)

    # Set the field to the default to prevent changes to the resource
    props[:onboot] = true

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [props]
  end

  # @api private
  def self.munge(pairs)
    props = {}

    # Unquote all values
    pairs.each_pair do |key, val|
      if (munged = val.gsub(%r{['"]}, ''))
        pairs[key] = munged
      end
    end

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    SLES_NAME_MAPPINGS.each_pair do |type_name, sles_name|
      next unless (val = pairs[sles_name])

      pairs.delete(sles_name)
      props[type_name] = val
    end

    # if we encounter VLAN_ID parameter, set the interface mode to :vlan
    pairs.each_pair do |key, _val|
      props[:mode] = :vlan if key == 'VLAN_ID'
    end
    pairs.delete('VLAN_ID')

    # mode is a property so it should always have a value
    props[:mode] ||= :raw

    # For all of the remaining values, blindly toss them into the options hash.
    props[:options] = pairs

    props[:method] = 'static' unless %w[none bootp dhcp].include? props[:method]

    props
  end

  def self.format_file(filename, providers)
    return '' if providers.empty?

    if providers.length > 1
      raise Puppet::DevError,
            "Unable to support multiple interfaces [#{providers.map(&:name).join(',')}] in a single file #{filename}"
    end

    provider = providers[0]
    props    = {}

    props = provider.options if provider.options && provider.options != :absent

    # Map everything to a flat hash
    SLES_NAME_MAPPINGS.each_key do |type_name|
      if (val = provider.send(type_name)) && val != :absent
        props[type_name] = val
      end
    end

    # :mode does not exist in SLES_NAME_MAPPINGS so we have to fetch it manually
    # note that the inverse operation is in .munge instead of parse_file
    val = provider.send(:mode)
    props['VLAN_ID'] = provider.options['VLAN_ID'] if val == :vlan

    pairs = unmunge props

    pairs.each_with_object('') do |(key, value), str|
      str << %(#{key}=#{value}\n)
    end
  end

  def self.unmunge(props)
    pairs = {}

    SLES_NAME_MAPPINGS.each_pair do |type_name, sles_name|
      if (val = props[type_name])
        props.delete(type_name)
        pairs[sles_name] = val
      end
    end

    pairs.merge! props

    pairs.each_pair do |key, val|
      pairs[key] = %("#{val}") if val.is_a?(String) && val.match(%r{\s+})
    end

    pairs
  end

  def self.post_flush_hook(filename)
    File.chmod(0o644, filename)
  end
end
