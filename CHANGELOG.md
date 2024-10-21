# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v2.2.1](https://github.com/voxpupuli/puppet-network/tree/v2.2.1) (2024-10-21)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v2.2.0...v2.2.1)

**Fixed bugs:**

- Ensure boolean properties munged [\#335](https://github.com/voxpupuli/puppet-network/pull/335) ([treydock](https://github.com/treydock))
- network\_config::redhat: allow "\_" in network interface names [\#331](https://github.com/voxpupuli/puppet-network/pull/331) ([olifre](https://github.com/olifre))

## [v2.2.0](https://github.com/voxpupuli/puppet-network/tree/v2.2.0) (2024-01-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v2.1.0...v2.2.0)

**Implemented enhancements:**

- Support puppet-filemapper 4.0.0 [\#319](https://github.com/voxpupuli/puppet-network/pull/319) ([silug](https://github.com/silug))

**Closed issues:**

- installation of ifenslave during configuring bond fails on Debian \>=11 [\#305](https://github.com/voxpupuli/puppet-network/issues/305)

**Merged pull requests:**

- add EL8 Support and add missing EL flavours [\#316](https://github.com/voxpupuli/puppet-network/pull/316) ([SimonHoenscheid](https://github.com/SimonHoenscheid))
- Add Debian 11 and 12 support [\#308](https://github.com/voxpupuli/puppet-network/pull/308) ([hbog](https://github.com/hbog))

## [v2.1.0](https://github.com/voxpupuli/puppet-network/tree/v2.1.0) (2023-12-01)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v2.0.0...v2.1.0)

**Implemented enhancements:**

- Support 'local' routes with redhat provider [\#314](https://github.com/voxpupuli/puppet-network/pull/314) ([treydock](https://github.com/treydock))

**Merged pull requests:**

- Remove legacy top-scope syntax [\#313](https://github.com/voxpupuli/puppet-network/pull/313) ([smortex](https://github.com/smortex))

## [v2.0.0](https://github.com/voxpupuli/puppet-network/tree/v2.0.0) (2023-10-15)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v1.1.0...v2.0.0)

**Breaking changes:**

- Drop Puppet 6 support [\#298](https://github.com/voxpupuli/puppet-network/pull/298) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- Increased kmod dependency to \< 5.0.0 [\#311](https://github.com/voxpupuli/puppet-network/pull/311) ([canihavethisone](https://github.com/canihavethisone))
- Add Puppet 8 support [\#303](https://github.com/voxpupuli/puppet-network/pull/303) ([bastelfreak](https://github.com/bastelfreak))
- puppetlabs/stdlib: Allow 9.x [\#302](https://github.com/voxpupuli/puppet-network/pull/302) ([bastelfreak](https://github.com/bastelfreak))
- Add SLES support to network\_route and network\_config types [\#301](https://github.com/voxpupuli/puppet-network/pull/301) ([laugmanuel](https://github.com/laugmanuel))

**Fixed bugs:**

- Removed deprecated and unused puppet-boolean dependency [\#310](https://github.com/voxpupuli/puppet-network/pull/310) ([canihavethisone](https://github.com/canihavethisone))

**Closed issues:**

- Support for SLES [\#300](https://github.com/voxpupuli/puppet-network/issues/300)

## [v1.1.0](https://github.com/voxpupuli/puppet-network/tree/v1.1.0) (2023-04-07)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v1.0.2...v1.1.0)

**Closed issues:**

- The 'options' property of the network\_route type doesn't do anything [\#295](https://github.com/voxpupuli/puppet-network/issues/295)

## [v1.0.2](https://github.com/voxpupuli/puppet-network/tree/v1.0.2) (2023-04-06)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v1.0.1...v1.0.2)

**Implemented enhancements:**

- Allow for setting 'options' in network\_route on RHEL-like OS's [\#294](https://github.com/voxpupuli/puppet-network/pull/294) ([natemccurdy](https://github.com/natemccurdy))
- Replace the IPAddress gem with the built-in IPAddr class [\#290](https://github.com/voxpupuli/puppet-network/pull/290) ([imp-](https://github.com/imp-))

**Closed issues:**

- Unable to set correct netmask for IPv6 [\#267](https://github.com/voxpupuli/puppet-network/issues/267)

**Merged pull requests:**

- puppet-lint: autofix [\#291](https://github.com/voxpupuli/puppet-network/pull/291) ([bastelfreak](https://github.com/bastelfreak))

## [v1.0.1](https://github.com/voxpupuli/puppet-network/tree/v1.0.1) (2022-05-20)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- Attempt to fix nil:Class errors in RHEL [\#284](https://github.com/voxpupuli/puppet-network/pull/284) ([oniGino](https://github.com/oniGino))

## [v1.0.0](https://github.com/voxpupuli/puppet-network/tree/v1.0.0) (2022-05-06)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.10.1...v1.0.0)

**Fixed bugs:**

- Change netmask to cidr for redhat/centos [\#209](https://github.com/voxpupuli/puppet-network/issues/209)
- Redhat route provider unable to parse new format of route file [\#169](https://github.com/voxpupuli/puppet-network/issues/169)
- Setup routes a CIDR, not full subnetmask [\#282](https://github.com/voxpupuli/puppet-network/pull/282) ([oniGino](https://github.com/oniGino))

**Closed issues:**

- unable to set /32 route [\#281](https://github.com/voxpupuli/puppet-network/issues/281)

## [v0.10.1](https://github.com/voxpupuli/puppet-network/tree/v0.10.1) (2021-10-28)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.10.0...v0.10.1)

**Fixed bugs:**

- Puppet facts not populating after 61b10ea7fc1861bd334f14aad456d3027592e68f [\#274](https://github.com/voxpupuli/puppet-network/issues/274)
- Don't prefix facts with `:` [\#278](https://github.com/voxpupuli/puppet-network/pull/278) ([bastelfreak](https://github.com/bastelfreak))

## [v0.10.0](https://github.com/voxpupuli/puppet-network/tree/v0.10.0) (2021-09-17)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.9.0...v0.10.0)

**Breaking changes:**

- Drop Puppet 4/5 support [\#272](https://github.com/voxpupuli/puppet-network/issues/272)
- Drop EoL CentOS 6 support [\#273](https://github.com/voxpupuli/puppet-network/pull/273) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- update version dependencies for boolean and filemappper [\#237](https://github.com/voxpupuli/puppet-network/issues/237)
- support non numerical aliases on redhat [\#255](https://github.com/voxpupuli/puppet-network/pull/255) ([LadyNamedLaura](https://github.com/LadyNamedLaura))

**Fixed bugs:**

- Correct VLAN\_RANGE\_REGEX. [\#248](https://github.com/voxpupuli/puppet-network/pull/248) ([KeithWard](https://github.com/KeithWard))

**Closed issues:**

- add puppet 6 support [\#250](https://github.com/voxpupuli/puppet-network/issues/250)
- Slave interfaces being created at everyrun [\#139](https://github.com/voxpupuli/puppet-network/issues/139)

**Merged pull requests:**

- Allow stdlib 8.0.0 [\#275](https://github.com/voxpupuli/puppet-network/pull/275) ([smortex](https://github.com/smortex))
- modulesync 4.2.0 & puppet-lint updates [\#268](https://github.com/voxpupuli/puppet-network/pull/268) ([bastelfreak](https://github.com/bastelfreak))
- Switch to rspec for testing. [\#266](https://github.com/voxpupuli/puppet-network/pull/266) ([KeithWard](https://github.com/KeithWard))
- Use confine to ensure `ip` is available for network fact [\#265](https://github.com/voxpupuli/puppet-network/pull/265) ([runejuhl](https://github.com/runejuhl))
- Remove duplicate CONTRIBUTING.md file [\#259](https://github.com/voxpupuli/puppet-network/pull/259) ([dhoppe](https://github.com/dhoppe))
- Bump version requirements for stdlib/Puppet [\#256](https://github.com/voxpupuli/puppet-network/pull/256) ([runejuhl](https://github.com/runejuhl))
- Get rid of all raise\_error warnings in the tests and align errors a bit [\#252](https://github.com/voxpupuli/puppet-network/pull/252) ([vStone](https://github.com/vStone))
- Stop using $::osfamily but use $facts\['osfamily'\] [\#251](https://github.com/voxpupuli/puppet-network/pull/251) ([vStone](https://github.com/vStone))
- allow puppetlabs/stdlib 5.x [\#247](https://github.com/voxpupuli/puppet-network/pull/247) ([bastelfreak](https://github.com/bastelfreak))
- Remove docker nodesets [\#244](https://github.com/voxpupuli/puppet-network/pull/244) ([bastelfreak](https://github.com/bastelfreak))
- drop EOL OSs; fix puppet version range [\#243](https://github.com/voxpupuli/puppet-network/pull/243) ([bastelfreak](https://github.com/bastelfreak))
- bump puppet to latest supported version 4.10.0 [\#241](https://github.com/voxpupuli/puppet-network/pull/241) ([bastelfreak](https://github.com/bastelfreak))
- \#237: increase version boundary for boolean and filemapper dependencies [\#238](https://github.com/voxpupuli/puppet-network/pull/238) ([kevpfowler](https://github.com/kevpfowler))
- Remove EOL operatingsystems [\#234](https://github.com/voxpupuli/puppet-network/pull/234) ([ekohl](https://github.com/ekohl))

## [v0.9.0](https://github.com/voxpupuli/puppet-network/tree/v0.9.0) (2017-11-13)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.8.0...v0.9.0)

**Merged pull requests:**

- Allow Type network\_config to take a Numeric value for the MTU parameter [\#229](https://github.com/voxpupuli/puppet-network/pull/229) ([lukebigum](https://github.com/lukebigum))

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

- prepare release: 0.8.0 [\#228](https://github.com/voxpupuli/puppet-network/pull/228) ([igalic](https://github.com/igalic))
- Fix github license detection [\#226](https://github.com/voxpupuli/puppet-network/pull/226) ([alexjfisher](https://github.com/alexjfisher))
- update gem provider for 4.x [\#216](https://github.com/voxpupuli/puppet-network/pull/216) ([igalic](https://github.com/igalic))

## [v0.7.0](https://github.com/voxpupuli/puppet-network/tree/v0.7.0) (2017-01-12)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/v0.6.1...v0.7.0)

**Merged pull requests:**

- release 0.7.0 [\#211](https://github.com/voxpupuli/puppet-network/pull/211) ([bastelfreak](https://github.com/bastelfreak))
- Set min version\_requirement for Puppet + bump deps [\#208](https://github.com/voxpupuli/puppet-network/pull/208) ([juniorsysadmin](https://github.com/juniorsysadmin))
- Fix `mock_with` in `.sync.yml` [\#202](https://github.com/voxpupuli/puppet-network/pull/202) ([alexjfisher](https://github.com/alexjfisher))
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
- Contain instead of deprecated include [\#113](https://github.com/voxpupuli/puppet-network/pull/113) ([JimPanic](https://github.com/JimPanic))
- Fix test runs by using strings as cases for $::osfamily [\#112](https://github.com/voxpupuli/puppet-network/pull/112) ([JimPanic](https://github.com/JimPanic))
- Do not try to build Puppet 4 with Ruby 1.8.7 [\#110](https://github.com/voxpupuli/puppet-network/pull/110) ([JimPanic](https://github.com/JimPanic))
- Actually use the env variable set in .travis.yml [\#109](https://github.com/voxpupuli/puppet-network/pull/109) ([JimPanic](https://github.com/JimPanic))
- Release version 0.5.x in the puppet-community namespace [\#106](https://github.com/voxpupuli/puppet-network/pull/106) ([ffrank](https://github.com/ffrank))
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
- Ommit lacp\_rate for non 802.3ad mode [\#67](https://github.com/voxpupuli/puppet-network/pull/67) ([jskarpe](https://github.com/jskarpe))
- Two fixes for RedHat: [\#57](https://github.com/voxpupuli/puppet-network/pull/57) ([jasperla](https://github.com/jasperla))
- Interface mode property [\#56](https://github.com/voxpupuli/puppet-network/pull/56) ([jhoblitt](https://github.com/jhoblitt))
- Fix for issue \#43 [\#52](https://github.com/voxpupuli/puppet-network/pull/52) ([wolfspyre](https://github.com/wolfspyre))
- added link to debian package ifupdown-extra [\#51](https://github.com/voxpupuli/puppet-network/pull/51) ([c33s](https://github.com/c33s))
- ensure that network\_config redhat provider flushed files have a consiste... [\#49](https://github.com/voxpupuli/puppet-network/pull/49) ([jhoblitt](https://github.com/jhoblitt))
- Redhat provider tagged interfaces [\#47](https://github.com/voxpupuli/puppet-network/pull/47) ([jhoblitt](https://github.com/jhoblitt))
- Interface mtu property [\#46](https://github.com/voxpupuli/puppet-network/pull/46) ([jhoblitt](https://github.com/jhoblitt))
- Fix file expansion problem with PE. [\#40](https://github.com/voxpupuli/puppet-network/pull/40) ([nanliu](https://github.com/nanliu))

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

## [0.4.1](https://github.com/voxpupuli/puppet-network/tree/0.4.1) (2013-08-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.5.0-rc1...0.4.1)

**Closed issues:**

- Skip munge in full netmask addresses [\#54](https://github.com/voxpupuli/puppet-network/issues/54)
- Unable to find property, Puppet 3.2.3 [\#50](https://github.com/voxpupuli/puppet-network/issues/50)
- Support ONPARENT option for aliases [\#41](https://github.com/voxpupuli/puppet-network/issues/41)
- No longer finding interface config scripts in CentOS [\#39](https://github.com/voxpupuli/puppet-network/issues/39)
- Bogus error - Could not evaluate: Unable to support multiple interfaces in a single file [\#38](https://github.com/voxpupuli/puppet-network/issues/38)

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

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3...0.0.4rc1)

## [0.0.3](https://github.com/voxpupuli/puppet-network/tree/0.0.3) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3rc2...0.0.3)

## [0.0.3rc2](https://github.com/voxpupuli/puppet-network/tree/0.0.3rc2) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.3rc1...0.0.3rc2)

## [0.0.3rc1](https://github.com/voxpupuli/puppet-network/tree/0.0.3rc1) (2012-10-22)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.2...0.0.3rc1)

## [0.0.2](https://github.com/voxpupuli/puppet-network/tree/0.0.2) (2012-10-16)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1...0.0.2)

**Fixed bugs:**

- interfaces provider fails when given a second interface to manage [\#4](https://github.com/voxpupuli/puppet-network/issues/4)

## [0.0.1](https://github.com/voxpupuli/puppet-network/tree/0.0.1) (2012-09-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1rc2...0.0.1)

## [0.0.1rc2](https://github.com/voxpupuli/puppet-network/tree/0.0.1rc2) (2012-09-18)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/0.0.1rc1...0.0.1rc2)

## [0.0.1rc1](https://github.com/voxpupuli/puppet-network/tree/0.0.1rc1) (2012-08-29)

[Full Changelog](https://github.com/voxpupuli/puppet-network/compare/8084b78c50d8efe1667ca7f907ef878f068e96d8...0.0.1rc1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
