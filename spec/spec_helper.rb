require 'puppet'
require 'mocha'

dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(dir, dir + File.join('..', 'lib'))

RSpec.configure do |config|
  config.mock_with :mocha
end
