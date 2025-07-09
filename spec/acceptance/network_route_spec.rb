# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'network_route' do
  it 'creates a route' do
    pp = <<-EOS
      include network
      if $facts['os']['family'] == 'RedHat' {
        package{ 'network-scripts': ensure => 'present'}
      }
      network_route { '10.0.0.1':
        ensure    => 'present',
        network   => 'local',
        interface => 'lo',
      }
    EOS
    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
  end
end
