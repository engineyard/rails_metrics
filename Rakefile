# encoding: UTF-8

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.join(File.dirname(__FILE__), 'lib', 'rails_metrics', 'version')

desc 'Default: run unit tests.'
task :default => :test

desc 'Test RailsMetrics'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for RailsMetrics'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'RailsMetrics'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "rails_metrics"
    s.version = RailsMetrics::VERSION
    s.summary = "Metrics measurement for your app on top of ActiveSupport::Notifications"
    s.email = "contact@engineyard.com"
    s.homepage = "http://github.com/engineyard"
    s.description = "Metrics measurement for your app on top of ActiveSupport::Notifications"
    s.authors = ['José Valim']
    s.files =  FileList["[A-Z]*", "{app,config,generators,lib}/**/*", "init.rb"]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
