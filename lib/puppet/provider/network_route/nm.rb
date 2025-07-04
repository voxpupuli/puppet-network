require 'json'
require 'yaml'
require 'ipaddr'

Puppet::Type.type(:network_route).provide(:nm) do
  # NetworkManager provider using nmstate for network route configuration.
  #
  # This provider uses nmstate to manage network routes through
  # NetworkManager. It converts Puppet network_route resources to nmstate
  # YAML configuration and applies them using the nmstatectl command.
  #
  # @see https://nmstate.io/
  # @see https://docs.fedoraproject.org/en-US/quick-docs/network-manager-quick-reference/

  desc 'NetworkManager provider using nmstate for routes'

  # Confine to systems that have nmstate
  commands nmstatectl: 'nmstatectl'

  # Confine to systems with systemd and NetworkManager active
  confine service_provider: :systemd
  confine true: system('systemctl', 'is-active', '--quiet', 'NetworkManager.service')

  # Default for systems with NetworkManager and nmstate
  defaultfor service_provider: :systemd

  has_feature :provider_options

  # Retrieve current network route state from nmstate
  def self.instances
    begin
      output = nmstatectl('show', '--json')
      state = JSON.parse(output)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Failed to get nmstate configuration: #{e.message}")
      return []
    rescue JSON::ParserError => e
      Puppet.debug("Failed to parse nmstate JSON output: #{e.message}")
      return []
    end

    instances = []
    return instances unless state['routes']

    # Process running routes
    state['routes']['running']&.each do |route|
      next unless route['next-hop-interface']
      next if route['destination'] == '::1/128' || route['destination'] == '127.0.0.0/8'

      instance_hash = build_route_instance(route)
      instances << new(instance_hash) if instance_hash
    end

    # Process config routes
    state['routes']['config']&.each do |route|
      next unless route['next-hop-interface']
      next if route['destination'] == '::1/128' || route['destination'] == '127.0.0.0/8'

      instance_hash = build_route_instance(route)
      instances << new(instance_hash) if instance_hash
    end

    instances.uniq { |instance| instance.name }
  end

  def self.build_route_instance(route)
    return nil unless route['destination'] && route['next-hop-interface']

    instance_hash = {
      ensure: :present,
      provider: :nm,
      interface: route['next-hop-interface']
    }

    # Handle destination network
    destination = route['destination']
    if ['0.0.0.0/0', '::/0'].include?(destination)
      instance_hash[:name] = 'default'
      instance_hash[:network] = 'default'
      instance_hash[:netmask] = destination.include?(':') ? '0' : '0.0.0.0'
    else
      begin
        ip_addr = IPAddr.new(destination)
        instance_hash[:name] = destination
        instance_hash[:network] = ip_addr.to_s

        if ip_addr.ipv4?
          # Convert CIDR to netmask for IPv4
          prefix_length = destination.split('/')[1].to_i
          instance_hash[:netmask] = prefix_to_netmask(prefix_length)
        else
          # For IPv6, use prefix length directly
          instance_hash[:netmask] = destination.split('/')[1] || '128'
        end
      rescue IPAddr::InvalidAddressError
        Puppet.debug("Skipping route with invalid destination: #{destination}")
        return nil
      end
    end

    # Handle gateway
    instance_hash[:gateway] = route['next-hop-address'] if route['next-hop-address']

    instance_hash
  end

  def self.prefetch(resources)
    instances.each do |instance|
      if (resource = resources[instance.name])
        resource.provider = instance
      end
    end
  end

  # Convert CIDR prefix length to netmask for IPv4
  def self.prefix_to_netmask(prefix_length)
    return nil unless prefix_length

    mask = (0xffffffff << (32 - prefix_length.to_i)) & 0xffffffff
    [
      (mask >> 24) & 0xff,
      (mask >> 16) & 0xff,
      (mask >> 8) & 0xff,
      mask & 0xff
    ].join('.')
  end

  # Convert netmask to CIDR prefix length for IPv4
  def netmask_to_prefix(netmask)
    return nil unless netmask

    begin
      require 'ipaddr'
      IPAddr.new(netmask).to_i.to_s(2).count('1')
    rescue StandardError
      # Fallback for simple netmasks
      simple_netmasks = {
        '255.255.255.255' => 32,
        '255.255.255.254' => 31,
        '255.255.255.252' => 30,
        '255.255.255.248' => 29,
        '255.255.255.240' => 28,
        '255.255.255.224' => 27,
        '255.255.255.192' => 26,
        '255.255.255.128' => 25,
        '255.255.255.0'   => 24,
        '255.255.254.0'   => 23,
        '255.255.252.0'   => 22,
        '255.255.248.0'   => 21,
        '255.255.240.0'   => 20,
        '255.255.224.0'   => 19,
        '255.255.192.0'   => 18,
        '255.255.128.0'   => 17,
        '255.255.0.0'     => 16,
        '255.254.0.0'     => 15,
        '255.252.0.0'     => 14,
        '255.248.0.0'     => 13,
        '255.240.0.0'     => 12,
        '255.224.0.0'     => 11,
        '255.192.0.0'     => 10,
        '255.128.0.0'     => 9,
        '255.0.0.0'       => 8,
      }
      simple_netmasks[netmask]
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_hash[:ensure] = :present
    apply_config
  end

  def destroy
    config = build_route_removal_config
    apply_nmstate_config(config)
    @property_hash.clear
  end

  def flush
    return unless @property_hash[:ensure] == :present

    apply_config
  end

  private

  def apply_config
    config = build_nmstate_config
    apply_nmstate_config(config)
  end

  def build_nmstate_config
    route_config = {
      'destination' => build_destination,
      'next-hop-interface' => @resource[:interface]
    }

    # Add gateway if specified and not a local route
    route_config['next-hop-address'] = @resource[:gateway] if @resource[:gateway] && @resource[:network] != 'local'

    # Add metric if specified in options
    if @resource[:options]
      options = parse_options(@resource[:options])
      route_config['metric'] = options['metric'].to_i if options['metric']
    end

    {
      'routes' => {
        'config' => [route_config]
      }
    }
  end

  def build_route_removal_config
    route_config = {
      'destination' => build_destination,
      'next-hop-interface' => @resource[:interface],
      'state' => 'absent'
    }

    # Add gateway for identification if present
    route_config['next-hop-address'] = @resource[:gateway] if @resource[:gateway] && @resource[:network] != 'local'

    {
      'routes' => {
        'config' => [route_config]
      }
    }
  end

  def build_destination
    case @resource[:network]
    when 'default'
      # Determine if this is IPv4 or IPv6 default route based on gateway
      if @resource[:gateway] && IPAddr.new(@resource[:gateway]).ipv6?
        '::/0'
      else
        '0.0.0.0/0'
      end
    when 'local'
      # Local routes are handled differently - they don't have a destination
      @resource[:name]
    else
      # Build CIDR notation from network and netmask
      if @resource[:netmask]
        begin
          network_addr = IPAddr.new(@resource[:network])
          if network_addr.ipv4?
            prefix_length = netmask_to_prefix(@resource[:netmask])
            "#{@resource[:network]}/#{prefix_length}"
          else
            # For IPv6, netmask should be a prefix length
            "#{@resource[:network]}/#{@resource[:netmask]}"
          end
        rescue IPAddr::InvalidAddressError
          raise Puppet::Error, "Invalid network address: #{@resource[:network]}"
        end
      else
        @resource[:network]
      end
    end
  end

  def parse_options(options_string)
    options = {}
    return options unless options_string

    options_string.split.each do |option|
      key, value = option.split('=', 2)
      options[key] = value if key && value
    end
    options
  end

  def apply_nmstate_config(config)
    # Write config to temporary file
    require 'tempfile'
    temp_file = Tempfile.new(['nmstate-route', '.yaml'])

    begin
      temp_file.write(config.to_yaml)
      temp_file.close

      # Apply the configuration
      nmstatectl('apply', temp_file.path)

      Puppet.info("Network route configuration applied: #{@resource[:name]}")
    ensure
      temp_file.unlink
    end
  end

  # Property getters and setters
  def network
    @property_hash[:network]
  end

  def network=(value)
    @property_hash[:network] = value
  end

  def netmask
    @property_hash[:netmask]
  end

  def netmask=(value)
    @property_hash[:netmask] = value
  end

  def gateway
    @property_hash[:gateway]
  end

  def gateway=(value)
    @property_hash[:gateway] = value
  end

  def interface
    @property_hash[:interface]
  end

  def interface=(value)
    @property_hash[:interface] = value
  end

  def options
    @property_hash[:options]
  end

  def options=(value)
    @property_hash[:options] = value
  end
end
