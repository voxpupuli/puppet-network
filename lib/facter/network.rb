require 'facter'
require 'open-uri'
require 'timeout'

#Gateway
# Expected output: The ip address of the nexthop/default router
Facter.add("network_nexthop_ip") do
  my_gw = nil
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
    #not all network configurations will have a nexthop. 
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.split(/\s+/)[2].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/).to_s
    end
    my_gw
  end
end

#Primary interface
#  Expected output: The specific interface name that the node uses to communicate with the nexthop
Facter.add("network_primary_interface") do
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
    #not all network configurations will have a nexthop. 
    #the ip tool expresses the presence of a nexthop with the word 'via'
    if gw_address.include? ' via '
      my_gw = gw_address.split(/\s+/)[2].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/).to_s
      fun = Facter::Util::Resolution.exec("/sbin/ip route get #{my_gw}").split("\n")[0]
      fun.split(/\s+/)[2].to_s
    #some network configurations simply have a link that all interactions are abstracted through  
    elsif gw_address.include? 'scope link'
      #since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      #lets just use 8.8.8.8 as far as a route goes.
      fun = Facter::Util::Resolution.exec("/sbin/ip route get 8.8.8.8").split("\n")[0]
      fun.split(/\s+/)[2].to_s
    end
  end
end

#Primary IP
#  Expected output: The ipaddress configred on the interface that communicates with the nexthop
Facter.add("network_primary_ip") do
  confine :kernel => :linux
  setcode do
    gw_address = Facter::Util::Resolution.exec('/sbin/ip route show 0/0')
    if gw_address.include? ' via '
      my_gw = gw_address.split(/\s+/)[2].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/).to_s
      fun = Facter::Util::Resolution.exec("/sbin/ip route get #{my_gw}").split("\n")[0]
      fun.split(/\s+/)[4].to_s
    elsif gw_address.include? 'scope link'
      #since we have no default route ip to determine where to send 'traffic not otherwise explicitly routed'
      #lets just use 8.8.8.8 as far as a route goes and grab our IP from there.
      fun = Facter::Util::Resolution.exec("/sbin/ip route get 8.8.8.8").split("\n")[0]
      fun.split(/\s+/)[4].to_s
    end
  end
end
