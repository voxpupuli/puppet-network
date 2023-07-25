# make it work on debian..
class network::bond::setup {
  case $facts['os']['family'] {
    'Debian': {
      package { 'ifenslave':
        ensure => present,
      }
    }
    'RedHat', default: {
      # Redhat installs the ifenslave command with the iputils package which
      # is available by default
    }
  }
}
