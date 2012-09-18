require 'puppetx/filemapper'

Puppet::Type.type(:network_config).provide(:redhat) do
  # Red Hat network_config network scripts provider.
  #
  # This provider manages the contents of /etc/networks-scripts/ifcfg-* to
  # manage non-volatile network configuration.
  #
  # @todo interface aliasing
  # @todo bonded interfaces
  #
  # @see https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html "Red Hat Interface Configuration Files"

  include PuppetX::FileMapper

  desc "Redhat network-scripts provider"

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  SCRIPT_DIRECTORY = "/etc/sysconfig/network-scripts"

  NAME_MAPPINGS = {
    :ipaddress  => 'IPADDR',
    :netmask    => 'NETMASK',
    :method     => 'BOOTPROTO',
    :onboot     => 'ONBOOT',
    :name       => 'DEVICE',
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
  # @return [Array<String>] All network-script config files on this machine.
  #
  # @example
  #   RedhatProvider.target_files
  #   # => ['/etc/sysconfig/network-scripts/ifcfg-eth0', '/etc/sysconfig/network-scripts/ifcfg-eth1']
  def self.target_files
    Dir["#{SCRIPT_DIRECTORY}/ifcfg-*"]
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
    lines.reject! { |line| line.match(/^\s*$/) }

    # Extract all known properties
    file_properties = lines.inject({}) do |hash, line|
      if (m = line.match /^(.+)=(.*)$/)
        key = m[1].strip
        val = m[2].strip
        hash[key] = val
      else
        raise Puppet::Error, "#{filename} is malformed"
      end
      hash
    end

    provider_properties = {}

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    NAME_MAPPINGS.each_pair do |property, redhat_name|
      provider_properties[property] = file_properties.delete(redhat_name)
    end

    # For all of the remaining values, blindly toss them into the options hash.
    provider_properties[:options] = file_properties unless file_properties.empty?

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [provider_properties]
  end

  def self.format_file(filename, providers)
    case providers.length
    when 0
      ''
    when 1
      provider = providers[0]
      lines = []

      lines << "DEVICE=#{provider.name}"
      NAME_MAPPINGS.each_pair do |typename, redhat_name|
        lines << "#{redhat_name}=#{provider.property(typename).value}"
      end
      # Map any general options to key/value pairs
      lines << options.map { |(key, val)| "#{key}=#{val}" }

      lines.join("\n")
    else
      raise Puppet::DevError, 'Unable to support multiple interfaces in a single file'
    end
  end
end
