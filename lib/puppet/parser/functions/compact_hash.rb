Puppet::Parser::Functions.newfunction(:compact_hash,
                                      type: :rvalue,
                                      arity: 1,
                                      doc: <<-EOD) do |args|
  compact_hash
  ============

  Compresses a hash to remove all elements whose values are nil or undef.

  Examples
  --------

  $example = {
    'one'  => 'two',
    'red'  => undef,
    'blue' => nil,
  }

  compact_hash($example)
  # => { 'one => 'two' }

  EOD

  hash = args[0]

  hash.reject { |_, val| val.nil? || val == :undef }
end
