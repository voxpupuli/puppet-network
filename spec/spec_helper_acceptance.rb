require 'beaker-rspec'
require 'pry'
test_name 'spec_helper_acceptance'

UNSUPPORTED_PLATFORMS = %w(Windows Solaris AIX).freeze

config = {
  'main' => {
    # 'storeconfigs' => 'true',
  }
}

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    step "Installing puppet on \'#{host}\'"
    # Install Puppet
    install_puppet_on(host, :version => '3.8.1')
    configure_puppet_on(host, config)
    pv = host.execute('puppet --version')
    step "Puppet Version: \'#{pv}\'"

    # LB: Gem 'ipaddress' required for voxpupuli/puppet-network Types to work
    host.execute('gem install ipaddress')

    # Required for binding tests.
    next unless fact('osfamily') == 'RedHat'
    version = fact('operatingsystemmajrelease')
    host.execute("yum localinstall -y http://yum.puppetlabs.com/puppetlabs-release-el-#{version}.noarch.rpm")
    host.execute('yum install -y tar git vim')
    if fact('operatingsystemmajrelease') =~ /7/ || fact('operatingsystem') =~ /Fedora/
      host.execute('yum install -y bzip2')
    end
  end
end

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  # Enable disabling of tests
  c.filter_run_excluding :broken => true

  c.before :suite do
    # deploy hiera
    hosts.each do |host|
      on host, "/bin/touch #{default['puppetpath']}/hiera.yaml"
      on host, "/bin/mkdir -p #{default['puppetpath']}/hieradata/"
    end

    # install modules from forge
    forge_modules = [
    ]
    forge_modules.each do |m|
      hosts.each do |host|
        step "Installing puppet module \'#{m}\' on \'#{host}\'"
        on host, puppet('module', 'install', m), :acceptable_exit_codes => [0, 1]
      end
    end

    # install modules from git
    # TODO: work out how to do branches and tags
    git_repos = [
      :mod => 'filemapper', :repo => 'https://github.com/voxpupuli/puppet-filemapper.git'
    ]
    git_repos.each do |g|
      hosts.each do |host|
        step "Installing puppet module \'#{g[:repo]}\' from git on \'#{host}\'"
        on host, "rm -Rf #{default['puppetpath']}/modules/#{g[:mod]}"
        on host, "git clone #{g[:repo]} #{default['puppetpath']}/modules/#{g[:mod]}", :acceptable_exit_codes => [0, 1]
      end
    end

    # Install module
    step "Installing this module and it's dependencies from \'#{module_root}\'"
    puppet_module_install(:source => module_root, :module_name => 'network')
  end
end
