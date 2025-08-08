# @summary Compresses a hash to remove all elements whose values are nil or undef
#
# @deprecated This function is deprecated. Use the network::compact_hash() function instead.
#
# This function compresses a hash to remove all elements whose values are nil or undef.
# It has been deprecated in favor of the network::compact_hash() function which provides
# the same functionality using modern Puppet function syntax.
#
# @param hash The hash to compress
# @return [Hash] A new hash with nil and undef values removed
#
# @example Compressing a hash
#   $example = {
#     'one'  => 'two',
#     'red'  => undef,
#     'blue' => nil,
#   }
#
#   compact_hash($example)
#   # => { 'one' => 'two' }
#
Puppet::Parser::Functions.newfunction(:compact_hash,
                                      type: :rvalue,
                                      arity: 1,
                                      doc: <<-EOD) do |args|
  @deprecated This function is deprecated. Use the network::compact_hash() function instead.

  Compresses a hash to remove all elements whose values are nil or undef.
                                      EOD

  Puppet.deprecation_warning('compact_hash() is deprecated. Use network::compact_hash() instead.')

  # Call the new network::compact_hash function
  call_function('network::compact_hash', args)
end
