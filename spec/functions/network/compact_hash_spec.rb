require 'spec_helper'

describe 'network::compact_hash' do
  it 'returns an empty hash when given an empty hash' do
    is_expected.to run.with_params({}).and_return({})
  end

  it 'returns a compacted hash with nil values removed' do
    is_expected.to run.
      with_params('key1' => 'value1', 'key2' => nil, 'key3' => '', 'key4' => false, 'key5' => true).
      and_return('key1' => 'value1', 'key3' => '', 'key4' => false, 'key5' => true)
  end
end
