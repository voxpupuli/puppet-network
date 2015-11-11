#!/usr/bin/env ruby

rubylib = []

modulepath = `bundle exec puppet config print modulepath`

modulepath.split(':').each { |path| rubylib += Dir.glob("#{path}/*/lib") }

ENV['RUBYLIB'] = rubylib.join(':')

Kernel.exec "bundle exec rspec #{ARGV.join(' ')}"
