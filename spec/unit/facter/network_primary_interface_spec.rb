# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/network'

describe ':network_primary_interface', type: :fact do
  subject(:fact) { Facter.fact(':network_primary_interface') }

  before do
    Facter.clear
    allow(Facter.fact(:networking)).to receive(:value).and_return({ 'primary' => 'eth1' })
  end

  it 'uses the built-in facts to determine the primary interface' do
    expect(fact.value).to eq('eth1')
  end
end
