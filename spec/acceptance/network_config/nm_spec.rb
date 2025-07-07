require 'spec_helper_acceptance'

describe 'network_config with nm provider' do
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
    end

    context 'managing a dummy interface' do
      let(:manifest) do
        <<-MANIFEST
        network_config { 'dummy0':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'manual',
          mtu       => 1500,
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_config { 'dummy0':
          ensure   => 'absent',
          provider => 'nm',
        }
        MANIFEST
      end

      after(:all) do
        # Cleanup - remove the dummy interface
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates a dummy interface' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the interface was created - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy0', acceptable_exit_codes: [0, 1])
        if result.exit_code != 0
          # Try with ip command as fallback
          result = shell('ip link show dummy0', acceptable_exit_codes: [0, 1])
          expect(result.exit_code).to eq(0), 'dummy0 interface was not created'
        end
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing a dummy interface with static IP' do
      let(:manifest) do
        <<-MANIFEST
        network_config { 'dummy1':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'static',
          family    => 'inet',
          ipaddress => '192.0.2.100',
          netmask   => '255.255.255.0',
          mtu       => 1500,
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_config { 'dummy1':
          ensure   => 'absent',
          provider => 'nm',
        }
        MANIFEST
      end

      after(:all) do
        # Cleanup - remove the dummy interface
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates a dummy interface with static IP' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the interface was created and has the IP - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy1', acceptable_exit_codes: [0, 1])
        if result.exit_code == 0
          expect(result.stdout).to match(%r{192\.0\.2\.100})
        else
          # Try with ip command as fallback
          result = shell('ip addr show dummy1')
          expect(result.stdout).to match(%r{192\.0\.2\.100})
        end
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing a dummy interface with IPv6' do
      let(:manifest) do
        <<-MANIFEST
        network_config { 'dummy2':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'static',
          family    => 'inet6',
          ipaddress => '2001:db8::100',
          netmask   => '64',
          mtu       => 1500,
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_config { 'dummy2':
          ensure   => 'absent',
          provider => 'nm',
        }
        MANIFEST
      end

      after(:all) do
        # Cleanup - remove the dummy interface
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates a dummy interface with IPv6' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the interface was created and has the IPv6 address - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy2', acceptable_exit_codes: [0, 1])
        if result.exit_code == 0
          expect(result.stdout).to match(%r{2001:db8::100})
        else
          # Try with ip command as fallback
          result = shell('ip addr show dummy2')
          expect(result.stdout).to match(%r{2001:db8::100})
        end
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'managing interface with provider options' do
      let(:manifest) do
        <<-MANIFEST
        network_config { 'dummy3':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'manual',
          mtu       => 1400,
          options   => { 'accept-ra' => false },
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_config { 'dummy3':
          ensure   => 'absent',
          provider => 'nm',
        }
        MANIFEST
      end

      after(:all) do
        # Cleanup - remove the dummy interface
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'creates a dummy interface with custom options' do
        # Apply the manifest
        apply_manifest(manifest, catch_failures: true)

        # Check if the interface was created - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy3', acceptable_exit_codes: [0, 1])
        if result.exit_code != 0
          # Try with ip command as fallback
          result = shell('ip link show dummy3', acceptable_exit_codes: [0, 1])
          expect(result.exit_code).to eq(0), 'dummy3 interface was not created'
        end
      end

      it 'is idempotent' do
        # Apply twice to ensure idempotency
        apply_manifest(manifest, catch_failures: true)
        apply_manifest(manifest, catch_changes: true)
      end
    end

    context 'updating interface configuration' do
      let(:initial_manifest) do
        <<-MANIFEST
        network_config { 'dummy4':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'static',
          family    => 'inet',
          ipaddress => '192.0.2.200',
          netmask   => '255.255.255.0',
          mtu       => 1500,
        }
        MANIFEST
      end

      let(:updated_manifest) do
        <<-MANIFEST
        network_config { 'dummy4':
          ensure    => 'present',
          provider  => 'nm',
          onboot    => true,
          method    => 'static',
          family    => 'inet',
          ipaddress => '192.0.2.201',
          netmask   => '255.255.255.0',
          mtu       => 1400,
        }
        MANIFEST
      end

      let(:cleanup_manifest) do
        <<-MANIFEST
        network_config { 'dummy4':
          ensure   => 'absent',
          provider => 'nm',
        }
        MANIFEST
      end

      after(:all) do
        # Cleanup - remove the dummy interface
        apply_manifest(cleanup_manifest, catch_failures: true)
      end

      it 'updates interface configuration' do
        # Apply the initial manifest
        apply_manifest(initial_manifest, catch_failures: true)

        # Verify initial configuration - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy4', acceptable_exit_codes: [0, 1])
        if result.exit_code == 0
          expect(result.stdout).to match(%r{192\.0\.2\.200})
        else
          # Try with ip command as fallback
          result = shell('ip addr show dummy4')
          expect(result.stdout).to match(%r{192\.0\.2\.200})
        end

        # Apply the updated manifest
        apply_manifest(updated_manifest, catch_failures: true)

        # Verify updated configuration - allow some time for NetworkManager to process
        sleep(2)
        result = shell('nmcli device show dummy4', acceptable_exit_codes: [0, 1])
        if result.exit_code == 0
          expect(result.stdout).to match(%r{192\.0\.2\.201})
        else
          # Try with ip command as fallback
          result = shell('ip addr show dummy4')
          expect(result.stdout).to match(%r{192\.0\.2\.201})
        end
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
      network_config { 'dummy0':
        ensure    => 'present',
        provider  => 'nm',
        onboot    => true,
        method    => 'manual',
      }
      MANIFEST
    end

    it 'fails gracefully when nmstatectl is not available' do
      # This should fail because nmstatectl is not available
      apply_manifest(manifest, expect_failures: true)
    end
  end
end
