# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"
require 'rubygems'

# To test RailsMetrics, you need to:
#
#   1) Install latest bundler with "gem install bundler"
#   2) Clone rails in git://github.com/rails/rails
#   3) Ensure rails checkout is in the same directory as rails_metrics' one
#   4) Bundle rails repository requirements with "gem bundle"
#   5) Move to test/dummy and run "rake db:migrate RAILS_ENV=test"
#   6) rake test
#
require File.expand_path("dummy/config/environment.rb",  File.dirname(__FILE__))
require 'rails/test_help'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = 'test.com'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  # Execute the block setting the given values and restoring old values after
  # the block is executed.
  def swap(object, new_values)
    old_values = {}
    new_values.each do |key, value|
      old_values[key] = object.send key
      object.send :"#{key}=", value
    end
    yield
  ensure
    old_values.each do |key, value|
      object.send :"#{key}=", value
    end
  end

  def wait
    ActiveSupport::Notifications.notifier.wait
  end

  # Sometimes we need to wait, until ActiveSupport::Notifications releases
  # that something was pushed to the Queue.
  def wait!
    sleep(0.1)
    wait
  end

  def instrument(*args, &block)
    ActiveSupport::Notifications.instrument(*args, &block)
  end
end