source 'https://rubygems.org'

def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

gem 'puppet', *location_for(ENV['PUPPET_VERSION'], '>= 2.7.0')
gem 'facter', '>= 1.6.2'

group :test, :development do
  gem 'rspec', '~> 2.10.0'
  gem 'mocha', '~> 0.10.5'
  gem 'rspec-puppet'
  gem 'rake'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
