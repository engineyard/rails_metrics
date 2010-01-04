require 'rubygems'

begin
  gem "test-unit"
rescue LoadError
end

begin
  gem "ruby-debug"
  require 'ruby-debug'
rescue LoadError
end

require 'test/unit'
require 'mocha'

# Configure Rails
ENV["RAILS_ENV"] = "test"
RAILS_ROOT = "anywhere"

require File.expand_path(File.dirname(__FILE__) + "/../../rails/vendor/gems/environment")
require 'active_support'
require 'active_record'
require 'action_mailer'
require 'action_controller'

# Add RailsMetrics to load path and load the main file
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'rails_metrics'

ActionController::Base.view_paths = File.join(File.dirname(__FILE__), 'views')

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
end