class network::bond::setup {

  case $osfamily {
    RedHat: {
      # Redhat installs the ifenslave command with the iputils package which
      # is available by default
    }
    Debian: {
      #Only defining 2.6 which I believe is across all debian version distributions at this point
      #If your version is missing, just ask!
      package { 'ifenslave-2.6':
        ensure => present,
      }
    }
  }
}
