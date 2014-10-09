# = Define: network::bridge
#
# Instantiate cross-platform bonded interfaces
#
# == Parameters
#
# === interface parameters
#
# [*ensure*]
#
# The ensure value for the bonding interface.
#
# Default: present
#
# [*ipaddress*]
#
# The IPv4 address of the interface.
#
# [*netmask*]
#
# The IPv4 network mask of the interface.
#
# [*method*]
#
# The network configuration method.
#
# [*onboot*]
#
# Whether to bring the interface up on boot.
#
# === Bridges parameters
#
# [*ports*]
#       this option must exist for the scripts to setup the bridge, with
#       it you specify the ports you want to add to your bridge,  either
#       using  "none" if you want a bridge without any interfaces or you
#       want to add them later using brctl, or a list of the  interfaces
#
# [*ageing*] = time
#        set ageing time, default is 300, can have a fractional part.
#
# [*bridgeprio*] = priority
#        set bridge priority, priority is between 0 and 65535, default is
#        32768, affects bridge id, lowest priority  bridge  will  be  the
#        root.
#
# [*fd*] = time
#        set  bridge  forward  delay  to time seconds, default is 15, can
#        have a fractional part.
#
# [*gcint*] = time
#        set garbage collection interval to time seconds, default  is  4,
#        can have a fractional part.
#
# [*hello*] = time
#        set  hello  time  to  time  seconds,  default  is  2, can have a
#        fractional part.
#
# [*hw*] = MAC address
#        set the Ethernet MAC address of all the bridge interfaces to the
#        specified  one  so  that the bridge ends up having this hardware
#        address as well. WARNING: use this only if you know what you are
#        doing,  changing  the MAC address of the cards may cause trouble
#        if you don’t know what you are  doing.  To  see  the  discussion
#        about  this  feature and the problems that can cause you can try
#        to have a look at the bug that asked for this  feature  visiting
#        http://bugs.debian.org/271406
#
# [*maxage*] = time
#        set  max  message age to time seconds, default is 20, can have a
#        fractional part.
#
# [*maxwait*] = time
#        forces to time seconds the maximum time that the  Debian  bridge
#        setup  scripts  will  wait  for  the  bridge ports to get to the
#        forwarding status, doesn’t allow factional part. If it is  equal
#        to 0 then no waiting is done.
#
# [*pathcost*] = port cost
#        set  path  cost  for a port, default is 100, port is the name of
#        the interface to which this setting applies.
#
# [*portprio*] = port priority
#        set port priority, default is 128, affects port id, port is  the
#        name of the interface to which this setting applies.
#
# [*stp*] = state
#        turn  spanning  tree protocol on/off, state values are on or yes
#        to turn stp on and any other thing to set it  off,  default  has
#        changed  to  off  for security reasons in latest kernels, so you
#        should specify if you want stp on or off with this  option,  and
#        not rely on your kernel’s default behaviour.
#
# [*waitport*] = time [ports]
#        wait for a max of time seconds for the specified ports to become
#        available, if no ports are specified  then  those  specified  on
#        ports  will be used here. Specifying no ports here should
#        not be used if we are using regex or "all" on  ports,  as
#        it wouldn’t work.

define network::bridge (
  $ports,
  $ensure    = present,
  $ipaddress = undef,
  $netmask   = undef,
  $method    = undef,
  $family    = undef,
  $onboot    = undef,
  $mtu       = undef,

  $ageing     = undef,
  $bridgeprio = undef,
  $fd         = undef,
  $gcint      = undef,
  $hello      = undef,
  $hw         = undef,
  $maxage     = undef,
  $maxwait    = undef,
  $pathcost   = undef,
  $portprio   = undef,
  $stp        = undef,
  $waitport   = undef,
  
) {

  require network::bridge::setup

  case $::osfamily {
    Debian: {
      network::bridge::debian { $name:
        ports     => $ports,
        ensure    => $ensure,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        method    => $method,
        family    => $family,
        onboot    => $onboot,
        mtu       => $mtu,
        
        fd        => $fd,
        stp       => $stp,
      }
    }

    default: {
      fail("network::bridge does not support osfamily '${::osfamily}'")
    }
  }
}
