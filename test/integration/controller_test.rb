require 'test_helper'

class ControllerTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all

    # Create two dummy notifications
    User.create!(:name => "User")
    Notification.welcome.deliver

    wait
  end
end
