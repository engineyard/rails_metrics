require 'test_helper'

class ControllerTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all

    # Create two dummy notifications
    User.create!(:name => "User")
    Notification.welcome.deliver

    wait
  end

  test "can navigate notifications" do
    get "/metrics"

    assert_contain "active_record.sql"
    assert_contain "action_mailer.deliver"
    assert_contain ActiveSupport::Notifications.instrumenter.id

    within Metric.first do
      click_link "Show"
    end

    assert_contain "active_record.sql"
    click_link "Back"

    within Metric.last do
      click_link "Destroy"
    end

    assert_contain "Metric \"action_mailer.deliver\" was destroyed with success"
    assert_not_contain "action_mailer.deliver"
  end
end
