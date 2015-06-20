class network::bridge::setup {

  case $::osfamily {
    RedHat: {
      # TODO
    }
    Debian: {
      package { 'bridge-utils':
        ensure => present,
      }
    }
  }
}
