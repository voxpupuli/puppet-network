class network::vlan::setup {

  case $::osfamily {
    RedHat: {
      # TODO
    }
    Debian: {
      package { 'vlan':
        ensure => present,
      }
    }
  }
}
