# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v0.9.0](https://github.com/voxpupuli/puppet-network/tree/v0.9.0) (2017-11-13)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.8.0...v0.9.0)

**Merged pull requests:**

- Allow Type network\_config to take a Numeric value for the MTU parameter [\#229](https://github.com/voxpupuli/puppet-network/pull/229) ([lukebigum](https://github.com/lukebigum))
- prepare release: 0.8.0 [\#228](https://github.com/voxpupuli/puppet-network/pull/228) ([igalic](https://github.com/igalic))

## [v0.8.0](https://github.com/voxpupuli/puppet-network/tree/v0.8.0) (2017-07-04)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.7.0...v0.8.0)

**Implemented enhancements:**

- BREAKING: replace validate\_integer with datatype & drop puppet3 support [\#220](https://github.com/voxpupuli/puppet-network/pull/220) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- Malformed debian interfaces file error when running puppet daemon [\#60](https://github.com/voxpupuli/puppet-network/issues/60)

**Closed issues:**

- Package\[ipaddress\]: Provider gem is not functional on this host [\#215](https://github.com/voxpupuli/puppet-network/issues/215)
- puppet-boolean module not available anymore via puppetforge [\#213](https://github.com/voxpupuli/puppet-network/issues/213)

**Merged pull requests:**

- Fix github license detection [\#226](https://github.com/voxpupuli/puppet-network/pull/226) ([alexjfisher](https://github.com/alexjfisher))
- update gem provider for 4.x [\#216](https://github.com/voxpupuli/puppet-network/pull/216) ([igalic](https://github.com/igalic))
- release 0.7.0 [\#211](https://github.com/voxpupuli/puppet-network/pull/211) ([bastelfreak](https://github.com/bastelfreak))

## [v0.7.0](https://github.com/voxpupuli/puppet-network/tree/v0.7.0) (2017-01-12)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.6.1...v0.7.0)

**Merged pull requests:**

- Set min version\_requirement for Puppet + bump deps [\#208](https://github.com/voxpupuli/puppet-network/pull/208) ([juniorsysadmin](https://github.com/juniorsysadmin))
- Fix `mock\_with` in `.sync.yml` [\#202](https://github.com/voxpupuli/puppet-network/pull/202) ([alexjfisher](https://github.com/alexjfisher))
- Use Facter 3 if available for some facts [\#200](https://github.com/voxpupuli/puppet-network/pull/200) ([rski](https://github.com/rski))
- rubocop: fix RSpec/ImplicitExpect [\#196](https://github.com/voxpupuli/puppet-network/pull/196) ([alexjfisher](https://github.com/alexjfisher))
- Add missing badges [\#195](https://github.com/voxpupuli/puppet-network/pull/195) ([dhoppe](https://github.com/dhoppe))

## [v0.6.1](https://github.com/voxpupuli/puppet-network/tree/v0.6.1) (2016-09-27)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.6.0...v0.6.1)

**Merged pull requests:**

- Fix name of filemapper dependency. [\#188](https://github.com/voxpupuli/puppet-network/pull/188) ([johanek](https://github.com/johanek))
- Make fact confinement ruby 1.8 compatible [\#187](https://github.com/voxpupuli/puppet-network/pull/187) ([alexjfisher](https://github.com/alexjfisher))

## [v0.6.0](https://github.com/voxpupuli/puppet-network/tree/v0.6.0) (2016-09-16)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.5.0...v0.6.0)

**Implemented enhancements:**

- ifupdown-extras required on Debian, but not installed [\#45](https://github.com/voxpupuli/puppet-network/issues/45)
- Deprecate/Remove :family property, add :ip6address property, add :ipv6 and :ipv4 features [\#16](https://github.com/voxpupuli/puppet-network/issues/16)
- Add a `network` class which installs the packages and gems required by [\#168](https://github.com/voxpupuli/puppet-network/pull/168) ([rski](https://github.com/rski))

**Fixed bugs:**

- Multiple interfaces with different families not supported [\#9](https://github.com/voxpupuli/puppet-network/issues/9)
- The interfaces provider does not support mapping sections [\#3](https://github.com/voxpupuli/puppet-network/issues/3)

**Closed issues:**

- Allow setting every possible option without using the options hash [\#166](https://github.com/voxpupuli/puppet-network/issues/166)
- undefined method `with\_env' for Facter::Util::Resolution:Class [\#162](https://github.com/voxpupuli/puppet-network/issues/162)
- innitial creation of debian routes sets options as `absent` [\#160](https://github.com/voxpupuli/puppet-network/issues/160)
- support for IPv6 routes [\#158](https://github.com/voxpupuli/puppet-network/issues/158)
- Clear-up documentation for then network plugin [\#154](https://github.com/voxpupuli/puppet-network/issues/154)
- Not clear where the ipaddress gem should be installed [\#152](https://github.com/voxpupuli/puppet-network/issues/152)
- RedHat routes provider puts 'absent' in the files [\#149](https://github.com/voxpupuli/puppet-network/issues/149)
- Git information is included in tar.gz [\#124](https://github.com/voxpupuli/puppet-network/issues/124)
- network \_route error on oralinux\(redhat\) [\#104](https://github.com/voxpupuli/puppet-network/issues/104)
- make a fresh release of this module [\#102](https://github.com/voxpupuli/puppet-network/issues/102)
- cannot add ipv6 address on debian [\#92](https://github.com/voxpupuli/puppet-network/issues/92)
- /etc/network/routes updated on every run [\#69](https://github.com/voxpupuli/puppet-network/issues/69)
- Reconfigure option does not work [\#68](https://github.com/voxpupuli/puppet-network/issues/68)
- Readme.md: network\_route requires 'network' parameter [\#53](https://github.com/voxpupuli/puppet-network/issues/53)
- Add validation for type values [\#7](https://github.com/voxpupuli/puppet-network/issues/7)

**Merged pull requests:**

- replace explicit symlinks with an autogenerated ones [\#183](https://github.com/voxpupuli/puppet-network/pull/183) ([igalic](https://github.com/igalic))
- Support for MTU on bonds. [\#182](https://github.com/voxpupuli/puppet-network/pull/182) ([vholer](https://github.com/vholer))
- Unfudge `writes 5 fields` test [\#178](https://github.com/voxpupuli/puppet-network/pull/178) ([alexjfisher](https://github.com/alexjfisher))
- Remove with\_env, and trust in PATH being correct [\#177](https://github.com/voxpupuli/puppet-network/pull/177) ([igalic](https://github.com/igalic))
- Fix a typo in the HEADER of generated files [\#170](https://github.com/voxpupuli/puppet-network/pull/170) ([roman-mueller](https://github.com/roman-mueller))
- Fix issue 69, backwards incompatible change [\#165](https://github.com/voxpupuli/puppet-network/pull/165) ([rski](https://github.com/rski))
- fix "absent" options [\#161](https://github.com/voxpupuli/puppet-network/pull/161) ([igalic](https://github.com/igalic))
- routes: add ability to parse IPv6 addresses [\#159](https://github.com/voxpupuli/puppet-network/pull/159) ([igalic](https://github.com/igalic))
- Don't write absent to redhat route files and test for this [\#157](https://github.com/voxpupuli/puppet-network/pull/157) ([rski](https://github.com/rski))
- soft fail on missing ipaddress gem [\#155](https://github.com/voxpupuli/puppet-network/pull/155) ([fraenki](https://github.com/fraenki))
- Update README to better reflect the current module state [\#150](https://github.com/voxpupuli/puppet-network/pull/150) ([rski](https://github.com/rski))

## [v0.5.0](https://github.com/voxpupuli/puppet-network/tree/v0.5.0) (2016-03-14)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.4.2...v0.5.0)

**Closed issues:**

- Malformed redhat files are generated [\#142](https://github.com/voxpupuli/puppet-network/issues/142)
- make module rubocop clean [\#141](https://github.com/voxpupuli/puppet-network/issues/141)
- provider on CentOS 6 [\#135](https://github.com/voxpupuli/puppet-network/issues/135)
- require 'ipaddress' breaks puppet runs [\#129](https://github.com/voxpupuli/puppet-network/issues/129)
- ipaddress gem requirement missing from readme [\#128](https://github.com/voxpupuli/puppet-network/issues/128)
- Travis CI lockup [\#127](https://github.com/voxpupuli/puppet-network/issues/127)
- vlan regex misses MANY 1000-3000, and vlans ending in \[6-9\] above 4000. [\#116](https://github.com/voxpupuli/puppet-network/issues/116)
- Failing to create dummy0 device on RHEL6 [\#115](https://github.com/voxpupuli/puppet-network/issues/115)
- Interface config created but device is not up [\#86](https://github.com/voxpupuli/puppet-network/issues/86)
- Interfaces are "created" every puppet run [\#42](https://github.com/voxpupuli/puppet-network/issues/42)

**Merged pull requests:**

- Update metadata.json, CHANGELOG for the 0.5.0 release [\#148](https://github.com/voxpupuli/puppet-network/pull/148) ([rski](https://github.com/rski))
- rubocop fixes, split a really long line [\#144](https://github.com/voxpupuli/puppet-network/pull/144) ([rski](https://github.com/rski))
- Make :absent attributes not get written to redhat files [\#143](https://github.com/voxpupuli/puppet-network/pull/143) ([rski](https://github.com/rski))
- Guard against :absent provider.options in redhat \(issue 115\) [\#140](https://github.com/voxpupuli/puppet-network/pull/140) ([rski](https://github.com/rski))
- Ignore new Debian Jessie's features [\#133](https://github.com/voxpupuli/puppet-network/pull/133) ([vide](https://github.com/vide))
- Mention the ipaddress gem requirement in the docs [\#130](https://github.com/voxpupuli/puppet-network/pull/130) ([rski](https://github.com/rski))
- Fix network facts on Gentoo [\#126](https://github.com/voxpupuli/puppet-network/pull/126) ([saz](https://github.com/saz))
- Allow an empty hash for options [\#123](https://github.com/voxpupuli/puppet-network/pull/123) ([derekhiggins](https://github.com/derekhiggins))
- updated version for module dependency camptocamp/kmod [\#122](https://github.com/voxpupuli/puppet-network/pull/122) ([dustyhorizon](https://github.com/dustyhorizon))
- Setup extra files for travis releases [\#120](https://github.com/voxpupuli/puppet-network/pull/120) ([igalic](https://github.com/igalic))
- travis fixes: introduce augeasversion fact [\#119](https://github.com/voxpupuli/puppet-network/pull/119) ([igalic](https://github.com/igalic))
- "fix" travis tests by installing the latest version of augeas [\#118](https://github.com/voxpupuli/puppet-network/pull/118) ([igalic](https://github.com/igalic))
- Fix vlan match bug per https://github.com/puppet-community/puppet-net… [\#117](https://github.com/voxpupuli/puppet-network/pull/117) ([robbat2](https://github.com/robbat2))
- Release version 0.5.x in the puppet-community namespace [\#106](https://github.com/voxpupuli/puppet-network/pull/106) ([ffrank](https://github.com/ffrank))

## [0.4.2](https://github.com/voxpupuli/puppet-network/tree/0.4.2) (2015-06-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.4.1...0.4.2)

**Closed issues:**

- Push a new version to the forge [\#103](https://github.com/voxpupuli/puppet-network/issues/103)
- Add support for `--tcp-mss` option [\#100](https://github.com/voxpupuli/puppet-network/issues/100)
- network\_config redhat provider fails in case DEVICE parameter is not present in ifcfg-\* file [\#89](https://github.com/voxpupuli/puppet-network/issues/89)
- Provider not working on Ubuntu 14.04 LTS ? [\#88](https://github.com/voxpupuli/puppet-network/issues/88)
- no support for pointopoint and gateway [\#83](https://github.com/voxpupuli/puppet-network/issues/83)
- Vagrant + Puppet [\#80](https://github.com/voxpupuli/puppet-network/issues/80)
- It runs but doesn't do anything on the agent [\#79](https://github.com/voxpupuli/puppet-network/issues/79)
- create option to overwrite /etc/network/interfaces explicitly  [\#78](https://github.com/voxpupuli/puppet-network/issues/78)
- Remove dependencies [\#71](https://github.com/voxpupuli/puppet-network/issues/71)
- Could not autoload network\_config [\#70](https://github.com/voxpupuli/puppet-network/issues/70)
- setting the default route on Debian [\#61](https://github.com/voxpupuli/puppet-network/issues/61)
- default network example does not work on RHEL [\#58](https://github.com/voxpupuli/puppet-network/issues/58)
- network\_\* facts don't work on OpenVZ [\#43](https://github.com/voxpupuli/puppet-network/issues/43)
- bond config in CentOS 6 work with this [\#32](https://github.com/voxpupuli/puppet-network/issues/32)
- rspec failures on RHEL6 [\#30](https://github.com/voxpupuli/puppet-network/issues/30)

**Merged pull requests:**

- Contain instead of deprecated include [\#113](https://github.com/voxpupuli/puppet-network/pull/113) ([JimPanic](https://github.com/JimPanic))
- Fix test runs by using strings as cases for $::osfamily [\#112](https://github.com/voxpupuli/puppet-network/pull/112) ([JimPanic](https://github.com/JimPanic))
- Do not try to build Puppet 4 with Ruby 1.8.7 [\#110](https://github.com/voxpupuli/puppet-network/pull/110) ([JimPanic](https://github.com/JimPanic))
- Actually use the env variable set in .travis.yml [\#109](https://github.com/voxpupuli/puppet-network/pull/109) ([JimPanic](https://github.com/JimPanic))
- Let travis invoke tests with the proper LOAD\_PATH and Puppet version set. [\#107](https://github.com/voxpupuli/puppet-network/pull/107) ([JimPanic](https://github.com/JimPanic))
- deprecate adrien-network [\#105](https://github.com/voxpupuli/puppet-network/pull/105) ([ffrank](https://github.com/ffrank))
- Bond improvements [\#95](https://github.com/voxpupuli/puppet-network/pull/95) ([vholer](https://github.com/vholer))
- Set mode "raw" to existing non-VLAN interfaces on Debian [\#94](https://github.com/voxpupuli/puppet-network/pull/94) ([vholer](https://github.com/vholer))
- On Debian write only non-empty auto/allow-hotplug interface parameters [\#93](https://github.com/voxpupuli/puppet-network/pull/93) ([vholer](https://github.com/vholer))
- Update links to travis [\#91](https://github.com/voxpupuli/puppet-network/pull/91) ([ekohl](https://github.com/ekohl))
- Use ifcfg script name in case DEVICE parameter is not specified on redhat network\_config provider [\#90](https://github.com/voxpupuli/puppet-network/pull/90) ([stzilli](https://github.com/stzilli))
- Fix: do not print properies if they are absent. [\#84](https://github.com/voxpupuli/puppet-network/pull/84) ([jordiclariana](https://github.com/jordiclariana))
- indent sub-entries to the in interfaces [\#82](https://github.com/voxpupuli/puppet-network/pull/82) ([igalic](https://github.com/igalic))
- remove network\_public\_ip fact [\#81](https://github.com/voxpupuli/puppet-network/pull/81) ([igalic](https://github.com/igalic))
- RHEL7/ CentOS7: adapt ifcfg detection to new device naming scheme [\#76](https://github.com/voxpupuli/puppet-network/pull/76) ([Xylakant](https://github.com/Xylakant))
- Add additional option support [\#74](https://github.com/voxpupuli/puppet-network/pull/74) ([dblessing](https://github.com/dblessing))
- Fixed failing network::bond test [\#72](https://github.com/voxpupuli/puppet-network/pull/72) ([aelsabbahy](https://github.com/aelsabbahy))
- Ommit lacp\_rate for non 802.3ad mode [\#67](https://github.com/voxpupuli/puppet-network/pull/67) ([Yuav](https://github.com/Yuav))
- Two fixes for RedHat: [\#57](https://github.com/voxpupuli/puppet-network/pull/57) ([jasperla](https://github.com/jasperla))
- Interface mode property [\#56](https://github.com/voxpupuli/puppet-network/pull/56) ([jhoblitt](https://github.com/jhoblitt))
- Fix for issue \#43 [\#52](https://github.com/voxpupuli/puppet-network/pull/52) ([wolfspyre](https://github.com/wolfspyre))

## [0.4.1](https://github.com/voxpupuli/puppet-network/tree/0.4.1) (2013-08-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.5.0-rc1...0.4.1)

**Closed issues:**

- Skip munge in full netmask addresses [\#54](https://github.com/voxpupuli/puppet-network/issues/54)
- Unable to find property, Puppet 3.2.3 [\#50](https://github.com/voxpupuli/puppet-network/issues/50)
- Support ONPARENT option for aliases [\#41](https://github.com/voxpupuli/puppet-network/issues/41)
- No longer finding interface config scripts in CentOS [\#39](https://github.com/voxpupuli/puppet-network/issues/39)
- Bogus error - Could not evaluate: Unable to support multiple interfaces in a single file [\#38](https://github.com/voxpupuli/puppet-network/issues/38)

**Merged pull requests:**

- added link to debian package ifupdown-extra [\#51](https://github.com/voxpupuli/puppet-network/pull/51) ([c33s](https://github.com/c33s))
- ensure that network\_config redhat provider flushed files have a consiste... [\#49](https://github.com/voxpupuli/puppet-network/pull/49) ([jhoblitt](https://github.com/jhoblitt))
- Redhat provider tagged interfaces [\#47](https://github.com/voxpupuli/puppet-network/pull/47) ([jhoblitt](https://github.com/jhoblitt))
- Interface mtu property [\#46](https://github.com/voxpupuli/puppet-network/pull/46) ([jhoblitt](https://github.com/jhoblitt))
- Fix file expansion problem with PE. [\#40](https://github.com/voxpupuli/puppet-network/pull/40) ([nanliu](https://github.com/nanliu))

## [0.5.0-rc1](https://github.com/voxpupuli/puppet-network/tree/0.5.0-rc1) (2013-05-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.4.0...0.5.0-rc1)

**Fixed bugs:**

- umask for built module is broken [\#24](https://github.com/voxpupuli/puppet-network/issues/24)

**Closed issues:**

- Network module responds poorly to ifcfg-NNN.bak files [\#36](https://github.com/voxpupuli/puppet-network/issues/36)
- spec fixture files contain illegal path characters on Windows [\#33](https://github.com/voxpupuli/puppet-network/issues/33)
- Facts for default interface [\#29](https://github.com/voxpupuli/puppet-network/issues/29)
- Request for comments: static routing configuration [\#20](https://github.com/voxpupuli/puppet-network/issues/20)
- No ipip tunnel support? Nor no IP alias support? [\#19](https://github.com/voxpupuli/puppet-network/issues/19)

**Merged pull requests:**

- Facts for issue 29 [\#35](https://github.com/voxpupuli/puppet-network/pull/35) ([wolfspyre](https://github.com/wolfspyre))

## [0.4.0](https://github.com/voxpupuli/puppet-network/tree/0.4.0) (2013-03-23)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.3.0...0.4.0)

**Closed issues:**

- debian interfaces parser fails if two spaces are between 'iface' and the device [\#26](https://github.com/voxpupuli/puppet-network/issues/26)
- Spec failures on redhat [\#25](https://github.com/voxpupuli/puppet-network/issues/25)

## [0.3.0](https://github.com/voxpupuli/puppet-network/tree/0.3.0) (2013-01-30)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.3.0-rc1...0.3.0)

## [0.3.0-rc1](https://github.com/voxpupuli/puppet-network/tree/0.3.0-rc1) (2013-01-24)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.2.0...0.3.0-rc1)

**Closed issues:**

- auto line is removed with reimplement\_debian\_parsing [\#22](https://github.com/voxpupuli/puppet-network/issues/22)
- Multiple 'up' lines in options hash [\#18](https://github.com/voxpupuli/puppet-network/issues/18)

**Merged pull requests:**

- Add support for non-volatile network routes on Debian [\#23](https://github.com/voxpupuli/puppet-network/pull/23) ([codec](https://github.com/codec))
- Add dependency reference in README to boolean mixin [\#21](https://github.com/voxpupuli/puppet-network/pull/21) ([robertstarmer](https://github.com/robertstarmer))

## [0.2.0](https://github.com/voxpupuli/puppet-network/tree/0.2.0) (2013-01-06)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.2.0-rc1...0.2.0)

**Implemented enhancements:**

- The network\_config type should have a :provider\_options feature [\#2](https://github.com/voxpupuli/puppet-network/issues/2)
- The network\_config type should have a :reconfigurable feature [\#1](https://github.com/voxpupuli/puppet-network/issues/1)

**Closed issues:**

- Redhat provider should be hotpluggable [\#15](https://github.com/voxpupuli/puppet-network/issues/15)

## [0.2.0-rc1](https://github.com/voxpupuli/puppet-network/tree/0.2.0-rc1) (2012-12-30)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.1.1...0.2.0-rc1)

**Fixed bugs:**

- While configuration checked interface incorrectly marked as changed [\#13](https://github.com/voxpupuli/puppet-network/issues/13)

**Closed issues:**

- Invalid value for method =\> loopback [\#10](https://github.com/voxpupuli/puppet-network/issues/10)

## [0.1.1](https://github.com/voxpupuli/puppet-network/tree/0.1.1) (2012-12-07)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.1.0...0.1.1)

**Fixed bugs:**

- Spec failures on ruby 1.9.3 [\#14](https://github.com/voxpupuli/puppet-network/issues/14)

## [0.1.0](https://github.com/voxpupuli/puppet-network/tree/0.1.0) (2012-12-04)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.1.0-rc1...0.1.0)

**Fixed bugs:**

- allow-hotplug section mangles interfaces file [\#11](https://github.com/voxpupuli/puppet-network/issues/11)

**Closed issues:**

- Support hotplug configurations [\#12](https://github.com/voxpupuli/puppet-network/issues/12)

## [0.1.0-rc1](https://github.com/voxpupuli/puppet-network/tree/0.1.0-rc1) (2012-11-27)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.4...0.1.0-rc1)

## [0.0.4](https://github.com/voxpupuli/puppet-network/tree/0.0.4) (2012-11-01)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.4rc1...0.0.4)

**Fixed bugs:**

- The redhat provider has poor support for options with strings [\#5](https://github.com/voxpupuli/puppet-network/issues/5)

**Closed issues:**

- network\_config properties should be validated [\#8](https://github.com/voxpupuli/puppet-network/issues/8)
- The redhat provider needs config \<-\> resource munging [\#6](https://github.com/voxpupuli/puppet-network/issues/6)

## [0.0.4rc1](https://github.com/voxpupuli/puppet-network/tree/0.0.4rc1) (2012-10-28)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3rc2...0.0.4rc1)

## [0.0.3rc2](https://github.com/voxpupuli/puppet-network/tree/0.0.3rc2) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3...0.0.3rc2)

## [0.0.3](https://github.com/voxpupuli/puppet-network/tree/0.0.3) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3rc1...0.0.3)

## [0.0.3rc1](https://github.com/voxpupuli/puppet-network/tree/0.0.3rc1) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.2...0.0.3rc1)

## [0.0.2](https://github.com/voxpupuli/puppet-network/tree/0.0.2) (2012-10-16)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1rc2...0.0.2)

**Fixed bugs:**

- interfaces provider fails when given a second interface to manage [\#4](https://github.com/voxpupuli/puppet-network/issues/4)

## [0.0.1rc2](https://github.com/voxpupuli/puppet-network/tree/0.0.1rc2) (2012-09-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1...0.0.1rc2)

## [0.0.1](https://github.com/voxpupuli/puppet-network/tree/0.0.1) (2012-09-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1rc1...0.0.1)

## [0.0.1rc1](https://github.com/voxpupuli/puppet-network/tree/0.0.1rc1) (2012-08-29)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/8084b78c50d8efe1667ca7f907ef878f068e96d8...0.0.1rc1)



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*