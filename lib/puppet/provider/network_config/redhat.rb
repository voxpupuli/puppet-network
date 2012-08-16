#
# TODO
#   - aliases
#   - bonded interfaces
Puppet::Type.type(:network_config).provide(:redhat) do
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
  }

  def select_file
    "#{SCRIPT_DIRECTORY}/ifcfg-#{@resource.name}"
  end

  def self.target_files
    Dir["#{SCRIPT_DIRECTORY}/ifcfg-*"]
  end

  def self.parse_file(filename, contents)
    lines = contents.split('\n').map { |line| line.sub(/#.*$/, '') }.reject { |line| line.match(/^\s+$/) }

    file_properties = lines.inject({}) do |hash, line|
      # XXX VALIDATION
      pair = line.split('=').map(&:strip)
      hash[pair[0]] = pair[1]
      hash
    end

    provider_properties = {}

    # For each interface attribute that we recognize it, add the value to the
    # hash with our expected label
    NAME_MAPPINGS.each_pair do |typename, redhat_name|
      provider_properties[typename] = file_properties.delete(redhat_name)
    end

    # For all of the remaining values, blindly toss them into the options hash.
    provider_properties[:options] = file_properties unless file_properties.empty?

    # The FileMapper mixin expects an array of providers, so we return the
    # single interface wrapped in an array
    [provider_properties]
  end

  def self.format_file(filename, providers)

    raise Puppet::DevError, 'Unable to support multiple interfaces in a single file' if providers.length > 1

    provider = providers[0]
    # XXX What to do if no providers passed?
    lines = []

    NAME_MAPPINGS.each_pair do |typename, redhat_name|
      lines << "#{redhat_name}=#{provider.property(typename).value}"
    end

    lines << options.map do |(key, val)|
      "#{key}=#{val}"
    end

    lines.join('\n')
  end
end
