require 'facter'
require 'open-uri'
require 'timeout'

# Facter 3 has new facts that we can use instead of trying to do it
# ourselves
def facter_3
  facter_version = Gem::Version.new(Facter.version)
  version3 = Gem::Version.new('3.0.0')
  facter_version >= version3
end

# Gateway
# Expected output: The ip address of the nexthop/default router
Facter.add('network_nexthop_ip') do
  confine :kernel => :linux # rubocop:disable Style/HashSyntax
  confine { Facter::Util::Resolution.which('ip') }

  my_gw = nil
  setcode do
    gw_address = Facter::Util::Resolution.exec('ip route show 0/0')
    # not all network configurations will have a nexthop.
    # the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.split(%r{\s+})[2].match(%r{^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$}).to_s
    end
    my_gw
  end
end

# Primary interface
#  Expected output: The specific interface name that the node uses to communicate with the nexthop
Facter.add('network_primary_interface') do
  confine :kernel => :linux # rubocop:disable Style/HashSyntax
  confine { Facter::Util::Resolution.which('ip') }

  setcode do
    next Facter.fact(:networking).value['primary'] if facter_3
    gw_address = Facter::Util::Resolution.exec('ip route show 0/0')
    # not all network configurations will have a nexthop.
    # the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.split(%r{\s+})[2].match(%r{^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$}).to_s
      fun = Facter::Util::Resolution.exec("ip route get #{my_gw}").split("\n")[0]
    # some network configurations simply have a link that all interactions are abstracted through
    elsif gw_address.include? 'scope link'
      # since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      # lets just use 8.8.8.8 as far as a route goes.
      fun = Facter::Util::Resolution.exec('ip route get 8.8.8.8').split("\n")[0]
    end
    fun.split(%r{dev\s+([^\s]*)\s+src\s+([^\s]*)})[1].to_s
  end
end

# Primary IP
#  Expected output: The ipaddress configured on the interface that communicates with the nexthop
Facter.add('network_primary_ip') do
  confine :kernel => :linux # rubocop:disable Style/HashSyntax
  confine { Facter::Util::Resolution.which('ip') }

  setcode do
    next Facter.fact(:networking).value['ip'] if facter_3
    gw_address = Facter::Util::Resolution.exec('ip route show 0/0')
    if gw_address.include? ' via '
      my_gw = gw_address.split(%r{\s+})[2].match(%r{^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$}).to_s
      fun = Facter::Util::Resolution.exec("ip route get #{my_gw}").split("\n")[0]
    elsif gw_address.include? 'scope link'
      # since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      # lets just use 8.8.8.8 as far as a route goes and grab our IP from there.
      fun = Facter::Util::Resolution.exec('ip route get 8.8.8.8').split("\n")[0]
    end
    fun.split(%r{dev\s+([^\s]*)\s+src\s+([^\s]*)})[2].to_s
  end
end
