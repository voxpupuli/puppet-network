require 'rake'
require 'yaml'
require 'rspec/core/rake_task'

def fixtures(category)
  root = File.dirname(__FILE__)
  yaml = YAML.load_file(File.expand_path('.fixtures.yml', root))

  fixtures = yaml["fixtures"]

  if fixtures.nil?
    raise ".fixtures.yml contained no top level 'fixtures' key"
  end

  fixtures[category] || {}
rescue => e
  raise e, "Could not load fixture data: #{e}"
end

namespace :fixture do

  desc "Prepare all fixture repositories"
  task :prepare do
    fixtures("repositories").each_pair do |name, remote|
      fixture_target = "spec/fixtures/modules/#{name}"
      sh "git clone '#{remote}' '#{fixture_target}'" unless File.exist? fixture_target
    end
  end

  desc "Remove all fixture repositories"
  task :remove do
    fixtures["repositories"].each_pair do |name, remote|
      fixture_target = "spec/fixtures/modules/#{name}"
      FileUtils.rm_rf fixture_target if File.exist? fixture_target
    end
  end
end

desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/{classes,defines,unit,functions,hosts}/**/*_spec.rb'
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
