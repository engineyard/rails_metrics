# encoding: UTF-8

require "rake"
require "rake/testtask"
require "rdoc/task"
require "fileutils"
require File.expand_path("../lib/rails_metrics/version", __FILE__)
require "bundler"

Bundler::GemHelper.install_tasks

desc "Default: run unit tests"
task :default => :test

desc "Prepare environment for tests"
task :prepare do
  FileUtils.cd File.expand_path("../test/dummy", __FILE__)
  system("rake db:create:all")
  system("rake db:migrate")
  system("rake db:test:clone")
end

desc "Start the server for the dummy application used in tests"
task :server do
  exec("test/dummy/script/rails server")
end

desc "Test RailsMetrics"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

desc "Generate documentation for RailsMetrics"
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "RailsMetrics"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include("README.rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

