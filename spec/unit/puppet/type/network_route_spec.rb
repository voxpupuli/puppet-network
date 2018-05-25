require 'spec_helper'
require 'puppet/type/network_route'

RSpec.describe 'the network_route type' do
  it 'loads' do
    expect(Puppet::Type.type(:network_route)).not_to be_nil
  end
end
