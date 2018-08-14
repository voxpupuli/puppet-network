require 'spec_helper'
require 'puppet/type/network_route'

RSpec.describe 'the network_route type' do
  it 'loads' do
    expect(Puppet::Type.type(:network_route)).not_to be_nil
  end

  context 'prefix is default' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        default_route: true,
      )
    end

    it 'prefix is set' do
      expect(resource[:prefix]).to eq 'default'
    end

    it 'name is set to prefix' do
      expect(resource[:name]).to eq 'default'
    end

    it 'default_route should be true' do
      expect(resource[:default_route]).to eq :true
    end

    it 'metric should be 100' do
      expect(resource[:metric]).to eq '100'
    end

    it 'protocol should be static' do
      expect(resource[:protocol]).to eq 'static'
    end
  end

  context 'with a non-default route' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: '10.155.255.0/24',
        default_route: false,
        metric: '600',
        source: '10.155.255.110'
      )
    end

    it 'prefix is set to network address' do
      expect(resource[:prefix]).to eq '10.155.255.0/24'
    end

    it 'default_route is false' do
      expect(resource[:default_route]).to eq :false
    end

    it 'metric is set to 600' do
      expect(resource[:metric]).to eq '600'
    end

    it 'source is set to 10.155.255.110' do
      expect(resource[:source]).to eq '10.155.255.110'
    end
  end

  context 'with gateway set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        gateway: '10.155.255.1'
      )
    end

    it 'gateway should be 10.155.255.1' do
      expect(resource[:gateway]).to eq '10.155.255.1'
    end
  end

  context 'with interface set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        interface: 'eth0'
      )
    end

    it 'interface should be eth0' do
      expect(resource[:interface]).to eq 'eth0'
    end
  end

  context 'with metric set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        metric: '400'
      )
    end

    it 'metric should be 400' do
      expect(resource[:metric]).to eq '400'
    end
  end

  context 'with table set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        table: 'main'
      )
    end

    it 'table should be main' do
      expect(resource[:table]).to eq 'main'
    end
  end

  context 'with source set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        source: '10.155.255.10'
      )
    end

    it 'source should be 10.155.255.10' do
      expect(resource[:source]).to eq '10.155.255.10'
    end
  end

  context 'with scope set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        scope: 'link'
      )
    end

    it 'scope should be link' do
      expect(resource[:scope]).to eq 'link'
    end
  end

  context 'with protocol set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        protocol: 'boot'
      )
    end

    it 'protocol should be boot' do
      expect(resource[:protocol]).to eq 'boot'
    end
  end

  context 'with mtu set' do
    let(:resource) do
      Puppet::Type.type('network_route').new(
        prefix: 'default',
        mtu: '1500'
      )
    end

    it 'mtu should be 1500' do
      expect(resource[:mtu]).to eq '1500'
    end
  end

  context 'with invalid scope' do
    it 'should raise an error' do
      expect { Puppet::Type.type('network_route').new(
        prefix: 'default',
        scope: 'fail'
      )}.to raise_error(Puppet::ResourceError)
    end
  end

  context 'with invalid protocol' do
    it 'should raise an error' do
      expect { Puppet::Type.type('network_route').new(
        prefix: 'default',
        protocol: 'fail'
      )}.to raise_error(Puppet::ResourceError)
    end
  end
end
