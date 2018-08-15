require 'spec_helper'

# nsure_module_defined('Puppet::Provider::NetworkRoute')
module Puppet::Provider::NetworkRoute; end
require 'puppet/provider/network_route/network_route'

RSpec.describe Puppet::Provider::NetworkRoute::NetworkRoute do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:route) do
    [
      {
        prefix: 'default',
        via: '10.0.2.2',
        dev: 'enp0s3',
        proto: 'dhcp',
        metric: '100'
      }
    ]
  end
  let(:network_route) do
    [
      {
        default_route: true,
        ensure: 'present',
        gateway: '10.0.2.2',
        interface: 'enp0s3',
        metric: '100',
        prefix: 'default',
        protocol: 'dhcp'
      }
    ]
  end

  describe '#puppet_munge(should)' do
    let(:should) { network_route[0] }

    it 'should parse network_route into iproute2 keys' do
      expect(provider.puppet_munge(should)).to eq(
        {
          dev: 'enp0s3',
          metric: '100',
          prefix: 'default',
          proto: 'dhcp',
          via: '10.0.2.2',
        }
      )
    end
  end

  describe '#get' do
    before(:each) do
      allow(provider).to receive(:routes_list).and_return(route) # rubocop:disable RSpec/SubjectStub
    end

    it 'processes resources' do
      expect(provider.get(context)).to eq(
      [{default_route: true,
        ensure: 'present',
        gateway: '10.0.2.2',
        interface: 'enp0s3',
        metric: '100',
        prefix: 'default',
        protocol: 'dhcp'}]
      )
    end
  end

  # describe 'create(context, name, should)' do
  #   it 'creates the resource' do
  #     expect(context).to receive(:notice).with(%r{\ACreating 'a'})

  #     provider.create(context, 'a', name: 'a', ensure: 'present')
  #   end
  # end

  # describe 'update(context, name, should)' do
  #   it 'updates the resource' do
  #     expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

  #     provider.update(context, 'foo', name: 'foo', ensure: 'present')
  #   end
  # end

  # describe 'delete(context, name, should)' do
  #   it 'deletes the resource' do
  #     expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

  #     provider.delete(context, 'foo')
  #   end
  # end
end
