require 'bundler'
require 'bundler/gem_tasks'
require 'rake/clean'
begin
    require 'rspec/core/rake_task'
      RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
CLEAN.include('pkg')

task default: :spec
