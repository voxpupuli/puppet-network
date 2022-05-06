# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/network'

describe 'network_primary_ip' do
  subject(:fact) { Facter.fact(:network_primary_ip) }

  before do
    Facter.clear
    allow(Facter.fact(:networking)).to receive(:value).and_return({ 'ip' => '192.168.178.3' })
  end

  it 'uses the built-in facts to resolve the primary ip address' do
    expect(fact.value).to eq('192.168.178.3')
  end
end
