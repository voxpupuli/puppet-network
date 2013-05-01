require 'spec_helper'

describe 'network::bond::setup', :type => :class do
  describe 'on Debian' do
    let(:facts) {{:osfamily => 'Debian'}}

    it { should contain_package('ifenslave-2.6') }
  end
end
