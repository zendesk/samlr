require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'bump/tasks'

Rake::TestTask.new do |test|
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task default: :test
