require 'json'
require 'yaml'

Puppet::Type.type(:network_config).provide(:nm) do
  # NetworkManager provider using nmstate for network configuration.
  #
  # This provider uses nmstate to manage network configuration through
  # NetworkManager. It converts Puppet network_config resources to nmstate
  # YAML configuration and applies them using the nmstatectl command.
  #
  # @see https://nmstate.io/
  # @see https://docs.fedoraproject.org/en-US/fedora/latest/system-administrators-guide/networking/NetworkManager/

  desc 'NetworkManager provider using nmstate'

  # Confine to systems that have NetworkManager and nmstate
  confine true: begin
    File.executable?('/usr/bin/nmstatectl') || File.executable?('/usr/local/bin/nmstatectl')
  end

  # Default for systems with NetworkManager and nmstate
  defaultfor do
    Facter.value(:service_provider) == 'systemd' && begin
      File.executable?('/usr/bin/nmstatectl') || File.executable?('/usr/local/bin/nmstatectl')
    end
  end

  has_feature :provider_options
  has_feature :hotpluggable
  has_feature :reconfigurable

  commands nmstatectl: 'nmstatectl'

  # Retrieve current network state from nmstate
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
    return instances unless state['interfaces']

    state['interfaces'].each do |interface|
      next unless interface['name']
      next if interface['type'] == 'loopback'

      instance_hash = {
        ensure: :present,
        name: interface['name'],
        provider: :nm
      }

      # Map interface state to network_config properties
      if interface['state'] == 'up'
        instance_hash[:onboot] = :true
      else
        instance_hash[:onboot] = :false
      end

      # Handle IP configuration
      if interface['ipv4'] && interface['ipv4']['enabled']
        if interface['ipv4']['dhcp']
          instance_hash[:method] = :dhcp
          instance_hash[:family] = :inet
        elsif interface['ipv4']['address'] && !interface['ipv4']['address'].empty?
          instance_hash[:method] = :static
          instance_hash[:family] = :inet
          first_addr = interface['ipv4']['address'][0]
          instance_hash[:ipaddress] = first_addr['ip']
          instance_hash[:netmask] = prefix_to_netmask(first_addr['prefix-length'])
        end
      elsif interface['ipv6'] && interface['ipv6']['enabled']
        if interface['ipv6']['dhcp']
          instance_hash[:method] = :dhcp
          instance_hash[:family] = :inet6
        elsif interface['ipv6']['address'] && !interface['ipv6']['address'].empty?
          instance_hash[:method] = :static
          instance_hash[:family] = :inet6
          first_addr = interface['ipv6']['address'][0]
          instance_hash[:ipaddress] = first_addr['ip']
          instance_hash[:netmask] = first_addr['prefix-length'].to_s
        end
      else
        instance_hash[:method] = :manual
      end

      # Handle MTU
      if interface['mtu']
        instance_hash[:mtu] = interface['mtu']
      end

      instances << new(instance_hash)
    end

    instances
  end

  def self.prefetch(resources)
    instances.each do |instance|
      if resource = resources[instance.name]
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
    rescue
      # Fallback for simple netmasks
      case netmask
      when '255.255.255.255' then 32
      when '255.255.255.254' then 31
      when '255.255.255.252' then 30
      when '255.255.255.248' then 29
      when '255.255.255.240' then 28
      when '255.255.255.224' then 27
      when '255.255.255.192' then 26
      when '255.255.255.128' then 25
      when '255.255.255.0' then 24
      when '255.255.254.0' then 23
      when '255.255.252.0' then 22
      when '255.255.248.0' then 21
      when '255.255.240.0' then 20
      when '255.255.224.0' then 19
      when '255.255.192.0' then 18
      when '255.255.128.0' then 17
      when '255.255.0.0' then 16
      when '255.254.0.0' then 15
      when '255.252.0.0' then 14
      when '255.248.0.0' then 13
      when '255.240.0.0' then 12
      when '255.224.0.0' then 11
      when '255.192.0.0' then 10
      when '255.128.0.0' then 9
      when '255.0.0.0' then 8
      else nil
      end
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
    config = {
      'interfaces' => [
        {
          'name' => @resource[:name],
          'type' => 'unknown',
          'state' => 'absent'
        }
      ]
    }

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
    interface_config = {
      'name' => @resource[:name],
      'type' => determine_interface_type,
      'state' => (@resource[:onboot] == :false) ? 'down' : 'up'
    }

    # Configure MTU
    if @resource[:mtu]
      interface_config['mtu'] = @resource[:mtu].to_i
    end

    # Configure IP settings based on method and family
    case @resource[:method]
    when :dhcp
      if @resource[:family] == :inet6
        interface_config['ipv6'] = {
          'enabled' => true,
          'dhcp' => true
        }
        interface_config['ipv4'] = { 'enabled' => false }
      else
        interface_config['ipv4'] = {
          'enabled' => true,
          'dhcp' => true
        }
        interface_config['ipv6'] = { 'enabled' => false }
      end
    when :static
      if @resource[:family] == :inet6
        address_config = {
          'ip' => @resource[:ipaddress],
          'prefix-length' => @resource[:netmask].to_i
        }
        interface_config['ipv6'] = {
          'enabled' => true,
          'dhcp' => false,
          'address' => [address_config]
        }
        interface_config['ipv4'] = { 'enabled' => false }
      else
        prefix_length = netmask_to_prefix(@resource[:netmask])
        address_config = {
          'ip' => @resource[:ipaddress],
          'prefix-length' => prefix_length
        }
        interface_config['ipv4'] = {
          'enabled' => true,
          'dhcp' => false,
          'address' => [address_config]
        }
        interface_config['ipv6'] = { 'enabled' => false }
      end
    when :manual, :none
      interface_config['ipv4'] = { 'enabled' => false }
      interface_config['ipv6'] = { 'enabled' => false }
    end

    # Add provider-specific options if present
    if @resource[:options] && !@resource[:options].empty?
      @resource[:options].each do |key, value|
        interface_config[key.to_s] = value
      end
    end

    {
      'interfaces' => [interface_config]
    }
  end

  def determine_interface_type
    # Try to determine interface type based on name patterns
    case @resource[:name]
    when /^eth\d+$/
      'ethernet'
    when /^enp\d+s\d+$/
      'ethernet'
    when /^ens\d+$/
      'ethernet'
    when /^wlan\d+$/, /^wlp\d+s\d+$/
      'wifi'
    when /^bond\d+$/
      'bond'
    when /^br\d+$/, /^bridge\d+$/
      'linux-bridge'
    when /\.\d+$/
      'vlan'
    else
      'ethernet' # Default to ethernet
    end
  end

  def apply_nmstate_config(config)
    # Write config to temporary file
    require 'tempfile'
    temp_file = Tempfile.new(['nmstate', '.yaml'])
    
    begin
      temp_file.write(config.to_yaml)
      temp_file.close

      # Apply the configuration
      nmstatectl('apply', temp_file.path)
      
      # If reconfigure is requested, we can check the interface state
      if @resource[:reconfigure] == :true
        # nmstate automatically applies the configuration,
        # so no additional reconfiguration is needed
        Puppet.info("Network configuration applied and interface reconfigured: #{@resource[:name]}")
      end
      
    ensure
      temp_file.unlink
    end
  end

  # Property getters
  def onboot
    @property_hash[:onboot]
  end

  def onboot=(value)
    @property_hash[:onboot] = value
  end

  def method
    @property_hash[:method]
  end

  def method=(value)
    @property_hash[:method] = value
  end

  def ipaddress
    @property_hash[:ipaddress]
  end

  def ipaddress=(value)
    @property_hash[:ipaddress] = value
  end

  def netmask
    @property_hash[:netmask]
  end

  def netmask=(value)
    @property_hash[:netmask] = value
  end

  def family
    @property_hash[:family]
  end

  def family=(value)
    @property_hash[:family] = value
  end

  def mtu
    @property_hash[:mtu]
  end

  def mtu=(value)
    @property_hash[:mtu] = value
  end

  def hotplug
    @property_hash[:hotplug]
  end

  def hotplug=(value)
    @property_hash[:hotplug] = value
  end

  def options
    @property_hash[:options] || {}
  end

  def options=(value)
    @property_hash[:options] = value
  end
end
