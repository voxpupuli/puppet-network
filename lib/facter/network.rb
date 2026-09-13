require 'facter'

Facter.add(:network_nexthop_ip) do
  confine kernel: 'Linux'
  confine { Facter::Core::Execution.which('ip') }
  my_gw = nil
  setcode do
    gw_address = Facter::Core::Execution.execute('ip route show 0/0')
    my_gw = gw_address.split(%r{\s+})[2].match(%r{^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$}).to_s if gw_address.include? ' via '
    my_gw
  end
end

Facter.add(:network_primary_interface) do
  confine kernel: 'Linux'

  setcode do
    Facter.value(:networking)['primary']
  end
end

Facter.add(:network_primary_ip) do
  confine kernel: 'Linux'

  setcode do
    Facter.value(:networking)['ip']
  end
end
