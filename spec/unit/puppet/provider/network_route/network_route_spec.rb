require 'spec_helper'

# nsure_module_defined('Puppet::Provider::NetworkRoute')
module Puppet::Provider::NetworkRoute; end
require 'puppet/provider/network_route/network_route'

RSpec.describe Puppet::Provider::NetworkRoute::NetworkRoute do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {:ensure=>"present",
            :prefix=>"default",
            :default_route=>true,
            :gateway=>"10.155.255.1",
            :interface=>"wlp3s0",
            :metric=>"600",
            :protocol=>"dhcp"},
           {:ensure=>"present",
            :prefix=>"10.155.255.0/24",
            :default_route=>false,
            :interface=>"wlp3s0",
            :metric=>"600",
            :source=>"10.155.255.110",
            :scope=>"link",
            :protocol=>"kernel"},
           {:ensure=>"present",
            :prefix=>"169.254.0.0/16",
            :default_route=>false,
            :interface=>"virbr0",
            :metric=>"1000",
            :scope=>"link"},
           {:ensure=>"present",
            :prefix=>"172.17.0.0/16",
            :default_route=>false,
            :interface=>"docker0",
            :source=>"172.17.0.1",
            :scope=>"link",
            :protocol=>"kernel"},
           {:ensure=>"present",
            :prefix=>"172.18.0.0/16",
            :default_route=>false,
            :interface=>"br-39a722eeac35",
            :source=>"172.18.0.1",
            :scope=>"link",
            :protocol=>"kernel"},
           {:ensure=>"present",
            :prefix=>"192.168.122.0/24",
            :default_route=>false,
            :interface=>"virbr0",
            :source=>"192.168.122.1",
            :scope=>"link",
            :protocol=>"kernel"}
      ]
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
