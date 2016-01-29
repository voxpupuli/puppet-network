require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:redhat) do
  # Red Hat network_config network scripts provider.
  #
  # This provider manages the contents of /etc/networks-scripts/ifcfg-* to
  # manage non-volatile network configuration.
  #
  # @see https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html "Red Hat Interface Configuration Files"

  include PuppetX::FileMapper

  desc 'Redhat network-scripts provider'

  confine :osfamily => :redhat
  defaultfor :osfamily => :redhat

  has_feature :hotpluggable
  has_feature :provider_options

  # @return [String] The path to network-script directory on redhat systems
  SCRIPT_DIRECTORY = '/etc/sysconfig/network-scripts'.freeze

  # The valid vlan ID range is 0-4095; 4096 is out of range
  VLAN_RANGE_REGEX = /\d{1,3}|40[0-9][0-5]/

  # @return [Regexp] The regular expression for interface scripts on redhat systems
  SCRIPT_REGEX     = /\Aifcfg-[a-z]+[a-z\d]+(?::\d+|\.#{VLAN_RANGE_REGEX})?\Z/

  NAME_MAPPINGS = {
    :ipaddress  => 'IPADDR',
    :netmask    => 'NETMASK',
    :method     => 'BOOTPROTO',
    :onboot     => 'ONBOOT',
    :name       => 'DEVICE',
    :hotplug    => 'HOTPLUG',
    :mtu        => 'MTU'
  }.freeze

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
    entries = Dir.entries(script_dir).select { |entry| entry.match SCRIPT_REGEX }
    entries.map { |entry| File.join(SCRIPT_DIRECTORY, entry) }
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
    # Split up the file into lines
    lines = contents.split("\n")
    # Strip out all comments
    lines.map! { |line| line.sub(/#.*$/, '') }
    # Remove all blank lines
    lines.reject! { |line| line =~ /^\s*$/ }

    Puppet.debug "parse_file(): got #{lines.length} lines from file #{filename} to parse"

    pair_regex = /^\s*(.+?)\s*=\s*(.*)\s*$/

    # Convert the data into key/value pairs
    # LB: replacing each_with_object() function with a more verbose version to preserve
    # compatability with Ruby 1.8.7
    # pairs = lines.each_with_object({}) do |line, hash|
    pairs = {}
    lines.each do |line|
      m = line.match(pair_regex)
      fail Puppet::Error, %(#{filename} is malformed; "#{line}" did not match "#{pair_regex}") if m.nil?
      key = m[1].strip
      val = m[2].strip
      Puppet.debug "parse_file(): Key=#{key}, Value=#{val}"
      pairs[key] = val
    end

    Puppet.debug "parse_file(): parsed #{pairs.size} keys from #{filename}"

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
      next unless (val = pairs[redhat_name])
      pairs.delete(redhat_name)
      Puppet.debug "munge(): Converted key #{redhat_name} to #{type_name}"
      props[type_name] = val
    end

    # if we encounter VLAN=yes set the interface mode to :vlan
    pairs.each_pair do |key, val|
      props[:mode] = :vlan if key == 'VLAN' && val == 'yes'
    end
    pairs.delete('VLAN')

    # mode is a property so it should always have a value
    props[:mode] ||= :raw

    # For all of the remaining values, blindly toss them into the options hash,
    # but downcase the keys
    props[:options] = {}
    pairs.each_pair do |key, val|
      props[:options][key.downcase] = val
    end

    [:onboot, :hotplug].each do |bool_property|
      if props[bool_property]
        props[bool_property] = (props[bool_property] == 'yes')
      end
    end

    props[:method] = 'static' unless %w(bootp dhcp).include? props[:method]

    props
  end

  def self.format_file(filename, providers)
    if providers.length == 0
      return ''
    elsif providers.length > 1
      fail Puppet::DevError, "Unable to support multiple interfaces [#{providers.map(&:name).join(',')}] in a single file #{filename}"
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

    # :mode does not exist in NAME_MAPPINGS so we have to fetch it manually
    # note that the inverse operation is in .munge instead of parse_file
    val = provider.send(:mode)
    props['VLAN'] = 'yes' if val == :vlan

    pairs = unmunge props

    # LB: replacing each_with_object() function to preserve compatability with Ruby 1.8.7
    # content = pairs.each_with_object('') do |(key, value), str|
    content = ''
    pairs.each do |key, value|
      # LB: do not write key-value pairs to disk that are 'absent' in Puppet
      Puppet.debug "format_file(): Key=#{key}, Value=#{value}"
      content << %(#{key}=#{value}\n)
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
      next unless (val = props[type_name])
      next if val == :absent
      props.delete(type_name)
      pairs[redhat_name] = val
      Puppet.debug "unmunge(): Converted property #{type_name}=#{val} to pair #{redhat_name}=#{val}"
    end

    props.each_pair do |key, val|
      next if val == :absent
      upkey = key.upcase
      if val =~ /\s/
        pairs[upkey] = %("#{val}")
      else
        pairs[upkey] = val.to_s
      end
      Puppet.debug "unmunge(): Adding property as pair #{upkey}=#{val}"
    end

    pairs
  end

  def self.post_flush_hook(filename)
    File.chmod(0644, filename)
  end
end
