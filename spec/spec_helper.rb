require 'puppet'
require 'rspec-puppet'
require 'mocha'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

RSpec.configure do |config|
  config.mock_with :mocha
end

# ---
# Configuration for puppet-rspec

fixture_path = File.expand_path('fixtures', File.dirname(__FILE__))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end
