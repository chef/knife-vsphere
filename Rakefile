require 'bundler'
require 'bundler/gem_tasks'
require 'rake/clean'
require 'yard'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
CLEAN.include('pkg')

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb'] # optional
  t.stats_options = ['--list-undoc'] # optional
end

task default: :spec
