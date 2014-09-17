require 'facter'
require 'open-uri'
require 'timeout'

# fact caching
# No TTL implementation as we want fresh facts always. Only use cache if
# external service is down.
#
module Facter
  module Util
    module Network

      @fact_cache_dir = '/var/tmp/fact_cache'
      @ntwrk_ip_cache = @fact_cache_dir + '/network_public_ip.yaml'
      @user_agent = 'Ruby/Facter'
    
      # rescue these errors with cached lookups
      @connection_errors = [
        OpenURI::HTTPError,
        Timeout::Error,
        Errno::EHOSTDOWN,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::ETIMEDOUT,
      ]
    
      # read from cache
      def self.cache_read(cache_file)
        # make sure directory exists
        unless File.exists? @fact_cache_dir
          Facter.debug("#{__method__} - #{@fact_cache_dir} did not exist - creating")
          FileUtils.mkdir_p(@fact_cache_dir)
        end
        # otherwise the file exists and we should be able to read from it
        # do yaml.load_file rather than read_file for 1.8.7 compatibility
        begin
          YAML.load_file(cache_file)
        rescue Errno::ENOENT
          # cache file did not exist? - would be the case on a first run, and
          # also in case of userdata being empty
          Facter.debug("#{__method__} - #{cache_file} did not exist")
          nil
        end
      end
    
      # write facts to cache
      def self.cache_write(facts,cache_file)
        # make sure directory exists
        unless File.exists? @fact_cache_dir
          Facter.debug("#{__method__} - #{@fact_cache_dir} did not exist - creating")
          FileUtils.mkdir_p(@fact_cache_dir)
        end
        Facter.debug("#{__method__} - attempting to write facts to #{cache_file}")
        out = File.open(cache_file, 'w') || File.new(cache_file, 'w')
        out.puts YAML.dump(facts)
        out.close
      end

      # get public IP
      def self.get_public_ip(url='http://ip-echo.appspot.com',timeout=2)
        public_ip = nil
        begin
          public_ip = Timeout::timeout(timeout) {
            open(
              url,
              'User-Agent'  => @user_agent
            ).read.match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/).to_s
          }
          # write cache on success
          cache_write({'network_public_ip' => public_ip},@ntwrk_ip_cache)
          public_ip
        rescue *@connection_errors => details
          Facter.warn("Could not retrieve data from #{url}: #{details.message}")
          Facter.warn("Attempting to use cached data..")
          cached = cache_read(@ntwrk_ip_cache)
          if cached.has_key?('network_public_ip')
            cached['network_public_ip']
          else
            nil
          end
        end
      end

    end
  end
end

include Facter::Util::Network

# Public IP
# Expected output: The public ipaddress of this node.
Facter.add("network_public_ip") do
  setcode do
    Facter::Util::Network.get_public_ip
  end
end

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
