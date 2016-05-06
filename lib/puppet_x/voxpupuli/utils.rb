module PuppetX
  module Voxpupuli
    module Utils
      def self.try(catch = ArgumentError, nope = false)
        yield
      rescue catch
        nope
      end
    end
  end
end
