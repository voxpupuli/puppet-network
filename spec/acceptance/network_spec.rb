require 'spec_helper_acceptance'

describe 'network' do
  context 'with default parameters' do
    let(:manifest) do
      'include network'
    end

    it 'applies the manifest without errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end
  end
end
