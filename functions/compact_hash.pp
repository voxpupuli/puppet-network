# @summary Compresses a hash by removing all elements whose values are `undef`
#
# @param hash The hash to compact
# @return A new hash with all `undef` values removed
# @example
#   $example = {
#     'one'  => 'two',
#     'red'  => undef,
#   }
# 
#   network::compact_hash($example)
#   # => { 'one => 'two' }
function network::compact_hash(Hash $hash) >> Hash {
  # Use the built-in `filter` function to remove all elements with `undef` values
  $hash.filter |$key, $value| { $value != undef }
}
