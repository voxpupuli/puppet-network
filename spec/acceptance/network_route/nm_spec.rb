require 'spec_helper_acceptance'

describe 'network_route with nm provider' do
  context 'when nmstate is available' do
    before(:all) do
      # Check if nmstate is available
      result = shell('which nmstatectl', acceptable_exit_codes: [0, 1])
      skip 'nmstatectl is not available' if result.exit_code != 0

      # Check if NetworkManager is running
      result = shell('systemctl is-active NetworkManager', acceptable_exit_codes: [0, 1])
      skip 'NetworkManager is not running' if result.exit_code != 0

      # Load dummy kernel module if not already loaded
      shell('modprobe dummy', acceptable_exit_codes: [0, 1])

      # Create a dummy interface for testing routes
      dummy_interface_manifest = <<-MANIFEST
        network_config { 'dummy10':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'static',
          family    => 'inet',
          ipaddress => '192.0.2.1',
          netmask   => '255.255.255.0',
          mtu       => 1500,
        }
      MANIFEST

      apply_manifest(dummy_interface_manifest, catch_failures: true)

      # Verify the dummy interface was created successfully
      result = shell('nmcli device show dummy10', acceptable_exit_codes: [0, 1])
      skip 'Could not create dummy interface dummy10' if result.exit_code != 0
    end

    after(:all) do
      # Cleanup - remove the dummy interface
      cleanup_manifest = <<-MANIFEST
        network_config { 'dummy10':
          ensure   => 'absent',
          provider => 'nm',
        }
      MANIFEST

      apply_manifest(cleanup_manifest, catch_failures: true)
    end

    context 'managing a simple route to unroutable address' do
      let(:manifest) do
        <<-MANIFEST
        network_route { '203.0.113.0/24':
          ensure    => 'present',
          provider  => 'nm',
          network   => '203.0.113.0',
          netmask   => '255.255.255.0',
          gateway   => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_route { '203.0.113.0/24':
          ensure   => 'absent',
          provider => 'nm',
          network  => '203.0.113.0',
          netmask  => '255.255.255.0',
          gateway  => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      after do
        # Cleanup - remove the route
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates a route to unroutable address' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the route was created
        result = shell('ip route show 203.0.113.0/24')
        expect(result.stdout).to match(%r{203\.0\.113\.0/24})
        expect(result.stdout).to match(%r{via 192\.0\.2\.254})
        expect(result.stdout).to match(%r{dev dummy10})
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing multiple routes' do
      let(:manifest) do
        <<-MANIFEST
        network_route { '198.51.100.0/24':
          ensure    => 'present',
          provider  => 'nm',
          network   => '198.51.100.0',
          netmask   => '255.255.255.0',
          gateway   => '192.0.2.254',
          interface => 'dummy10',
        }

        network_route { '203.0.113.128/25':
          ensure    => 'present',
          provider  => 'nm',
          network   => '203.0.113.128',
          netmask   => '255.255.255.128',
          gateway   => '192.0.2.253',
          interface => 'dummy10',
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_route { '198.51.100.0/24':
          ensure   => 'absent',
          provider => 'nm',
          network  => '198.51.100.0',
          netmask  => '255.255.255.0',
          gateway  => '192.0.2.254',
          interface => 'dummy10',
        }

        network_route { '203.0.113.128/25':
          ensure   => 'absent',
          provider => 'nm',
          network  => '203.0.113.128',
          netmask  => '255.255.255.128',
          gateway  => '192.0.2.253',
          interface => 'dummy10',
        }
        MANIFEST
      end

      after do
        # Cleanup - remove the routes
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates multiple routes' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if both routes were created
        result1 = shell('ip route show 198.51.100.0/24')
        expect(result1.stdout).to match(%r{198\.51\.100\.0/24})
        expect(result1.stdout).to match(%r{via 192\.0\.2\.254})

        result2 = shell('ip route show 203.0.113.128/25')
        expect(result2.stdout).to match(%r{203\.0\.113\.128/25})
        expect(result2.stdout).to match(%r{via 192\.0\.2\.253})
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing IPv6 routes' do
      before do
        # Create a separate dummy interface for IPv6
        ipv6_manifest = <<-MANIFEST
          network_config { 'dummy11':
            ensure    => 'present',
            provider  => 'nm',
            onboot    => true,
            method    => 'static',
            family    => 'inet6',
            ipaddress => '2001:db8::1',
            netmask   => '64',
            mtu       => 1500,
          }
        MANIFEST

        apply_manifest(ipv6_manifest, catch_failures: true)

        # Verify the IPv6 dummy interface was created successfully
        result = shell('nmcli device show dummy11', acceptable_exit_codes: [0, 1])
        skip 'Could not create IPv6 dummy interface dummy11' if result.exit_code != 0
      end

      after do
        # Cleanup - remove the IPv6 dummy interface
        cleanup_ipv6_manifest = <<-MANIFEST
          network_config { 'dummy11':
            ensure   => 'absent',
            provider => 'nm',
          }
        MANIFEST

        apply_manifest(cleanup_ipv6_manifest, catch_failures: true)
        apply_manifest(cleanup_manifest, catch_failures: true)
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      let(:manifest) do
        <<-MANIFEST
        network_route { '2001:db8:1::/48':
          ensure    => 'present',
          provider  => 'nm',
          network   => '2001:db8:1::',
          netmask   => '48',
          gateway   => '2001:db8::254',
          interface => 'dummy11',
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_route { '2001:db8:1::/48':
          ensure   => 'absent',
          provider => 'nm',
          network  => '2001:db8:1::',
          netmask  => '48',
          gateway  => '2001:db8::254',
          interface => 'dummy11',
        }
        MANIFEST
      end

      it 'creates IPv6 routes' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the IPv6 route was created
        result = shell('ip -6 route show 2001:db8:1::/48')
        expect(result.stdout).to match(%r{2001:db8:1::/48})
        expect(result.stdout).to match(%r{via 2001:db8::254})
        expect(result.stdout).to match(%r{dev dummy11})
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing routes with provider options' do
      let(:manifest) do
        <<-MANIFEST
        network_route { '198.51.100.64/26':
          ensure    => 'present',
          provider  => 'nm',
          network   => '198.51.100.64',
          netmask   => '255.255.255.192',
          gateway   => '192.0.2.254',
          interface => 'dummy10',
          options   => 'metric=150',
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_route { '198.51.100.64/26':
          ensure   => 'absent',
          provider => 'nm',
          network  => '198.51.100.64',
          netmask  => '255.255.255.192',
          gateway  => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      after do
        # Cleanup - remove the route
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates route with custom metric' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the route was created with custom metric
        result = shell('ip route show 198.51.100.64/26')
        expect(result.stdout).to match(%r{198\.51\.100\.64/26})
        expect(result.stdout).to match(%r{via 192\.0\.2\.254})
        expect(result.stdout).to match(%r{metric 150})
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'updating route configuration' do
      let(:initial_manifest) do
        <<-MANIFEST
        network_route { '198.51.100.192/26':
          ensure    => 'present',
          provider  => 'nm',
          network   => '198.51.100.192',
          netmask   => '255.255.255.192',
          gateway   => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      let(:updated_manifest) do
        <<-MANIFEST
        network_route { '198.51.100.192/26':
          ensure    => 'present',
          provider  => 'nm',
          network   => '198.51.100.192',
          netmask   => '255.255.255.192',
          gateway   => '192.0.2.253',
          interface => 'dummy10',
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_route { '198.51.100.192/26':
          ensure   => 'absent',
          provider => 'nm',
          network  => '198.51.100.192',
          netmask  => '255.255.255.192',
          gateway  => '192.0.2.253',
          interface => 'dummy10',
        }
        MANIFEST
      end

      after do
        # Cleanup - remove the route
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'updates route configuration' do
        # Apply the initial manifest
        apply_manifest(initial_manifest, catch_failures: true)

        # Verify initial configuration
        result = shell('ip route show 198.51.100.192/26')
        expect(result.stdout).to match(%r{via 192\.0\.2\.254})

        # Apply the updated manifest
        apply_manifest(updated_manifest, catch_failures: true)

        # Verify updated configuration
        result = shell('ip route show 198.51.100.192/26')
        expect(result.stdout).to match(%r{via 192\.0\.2\.253})
      end
    end

    context 'removing routes' do
      let(:manifest) do
        <<-MANIFEST
        network_route { '203.0.113.64/26':
          ensure    => 'present',
          provider  => 'nm',
          network   => '203.0.113.64',
          netmask   => '255.255.255.192',
          gateway   => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      let(:removal_manifest) do
        <<-MANIFEST
        network_route { '203.0.113.64/26':
          ensure   => 'absent',
          provider => 'nm',
          network  => '203.0.113.64',
          netmask  => '255.255.255.192',
          gateway  => '192.0.2.254',
          interface => 'dummy10',
        }
        MANIFEST
      end

      it 'removes routes correctly' do
        # Apply the manifest to create the route
        apply_manifest(manifest, catch_failures: true)

        # Verify route exists
        result = shell('ip route show 203.0.113.64/26')
        expect(result.stdout).to match(%r{203\.0\.113\.64/26})

        # Apply removal manifest
        apply_manifest(removal_manifest, catch_failures: true)

        # Verify route is removed
        result = shell('ip route show 203.0.113.64/26', acceptable_exit_codes: [0, 1])
        expect(result.stdout).not_to match(%r{203\.0\.113\.64/26})
      end
    end
  end

  context 'when nmstate is not available' do
    before(:all) do
      # Check if nmstate is available
      result = shell('which nmstatectl', acceptable_exit_codes: [0, 1])
      skip 'nmstatectl is available' if result.exit_code == 0
    end

    let(:manifest) do
      <<-MANIFEST
      network_route { '203.0.113.0/24':
        ensure    => 'present',
        provider  => 'nm',
        network   => '203.0.113.0',
        netmask   => '255.255.255.0',
        gateway   => '192.0.2.254',
        interface => 'eth0',
      }
      MANIFEST
    end

    it 'fails gracefully when nmstatectl is not available' do
      # This should fail because nmstatectl is not available
      apply_manifest(manifest, expect_failures: true)
    end
  end
end
