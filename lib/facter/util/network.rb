require 'open-uri'
require 'timeout'
#Namespacing
module Facter
module Util
module Network

def self.can_connect?(wait_sec,url)
  Timeout::timeout(wait_sec) do
    open(url)
    #yay! we can connect!
    return true
  end
    rescue Timeout::Error
    # Something raised an exception. It might be good to only catch Timeout::TimeoutError    # or whatever the Timeout.timeout call will raise.
      return false
    end
  end
end
end