# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/network'

describe 'network_nexthop_ip fact' do
  subject(:fact) { Facter.fact(:network_nexthop_ip) }

  before do
    # perform any action that should be run before every test
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(Facter::Core::Execution).to receive(:which).with('ip').and_return('/usr/bin/ip')
    allow(Facter::Core::Execution).to receive(:execute)
  end

  it 'returns the gateway' do
    expect(Facter::Core::Execution).to receive(:execute).with('ip route show 0/0').and_return('default via 192.168.178.1 dev eth0') # rubocop:disable RSpec/MessageSpies
    expect(fact.value).to eq('192.168.178.1')
  end
end
