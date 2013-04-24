class network::bond::setup {

  case $::osfamily {
    RedHat: {
      # Redhat installs the ifenslave command with the iputils package which
      # is available by default
    }
    Debian: {
      package { 'ifenslave-2.6':
        ensure => present,
      }
    }
  }
}
