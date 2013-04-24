require 'facter'
require 'facter/util/network'
require 'open-uri'
require 'timeout'

#Public IP
Facter.add("network_public_ip") do
  setcode do
    url='http://ip-echo.appspot.com'
    if Facter::Util::Network.can_connect?(1,url)
      open(url, 'User-Agent' => 'Ruby/Facter').read.to_s
    end
  end
end
#Gateway
my_gw = nil
Facter.add("network_nexthop_ip") do
  confine :kernel => :linux
  gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
  if gw_address
    my_gw = gw_address.split(/\s+/)[2].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/).to_s
  end
  setcode { my_gw }
end
if my_gw
  fun = Facter::Util::Resolution.exec("/sbin/ip route get #{my_gw}").split("\n")[0]
  if fun
    Facter.add("network_primary_interface") do
      setcode { fun.split(/\s+/)[2].to_s }
    end
    Facter.add("network_primary_ip") do
      setcode { fun.split(/\s+/)[4].to_s }
    end
  end
end