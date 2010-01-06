# Configure Rails Envinronment
ENV["RAILS_ENV"] = RAILS_ENV = "test"
require 'rubygems'

# To test RailsMetrics, you need to:
#
#   1) Install latest bundler with "gem install bundler"
#   2) Clone rails in git://github.com/rails/rails
#   3) Bundle rails repository requirements with "gem bundle"
#   4) Ensure rails checkout is in the same directory as rails_metrics' one
#   5) rake test
#
require File.expand_path("dummy/config/environment.rb",  File.dirname(__FILE__))

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate(Rails.root.join("db/migrate/"))