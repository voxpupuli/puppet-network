PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, 'lib'))
fixture_path = File.expand_path(File.join('spec', 'fixtures'), PROJECT_ROOT)
$LOAD_PATH.concat(Dir.glob(File.join(fixture_path, 'modules', '*', 'lib')))
