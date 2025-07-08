# @summary Setup bonding support for different operating systems
#
# This class installs the necessary packages for network bonding support.
# On Debian systems, it installs the ifenslave package. On RedHat systems,
# the ifenslave command is available by default with the iputils package.
#
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
