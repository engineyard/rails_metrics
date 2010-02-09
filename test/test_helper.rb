# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

# To test RailsMetrics, you need to:
#
#   1) Install latest bundler with "gem install bundler"
#   2) bundle install
#   3) rake prepare
#   4) rake test
#
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Webrat.configure do |config|
  config.mode = :rails
  config.open_error_files = false
end

# Add support to load paths so we can overwrite broken webrat setup
$:.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  setup do
    wait
    RailsMetrics.set_store { Metric }
  end
end