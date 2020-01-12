# make it work on debian..
class network::bond::setup {

  case $facts['os']['family'] {
    'Debian': {
      package { 'ifenslave-2.6':
        ensure => present,
      }
    }
    'RedHat', default: {
      # Redhat installs the ifenslave command with the iputils package which
      # is available by default
    }
  }
}
