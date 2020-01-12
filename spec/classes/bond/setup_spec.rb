require 'spec_helper'

describe 'network::bond::setup', type: :class do
  describe 'on Debian' do
    let(:facts) do
      {
        os: { family: 'Debian' }
      }
    end

    it { is_expected.to contain_package('ifenslave-2.6') }
  end
end
