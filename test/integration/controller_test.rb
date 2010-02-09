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
    get "/rails_metrics"

    assert_contain "To"
    assert_contain "active_record.sql"
    assert_contain "action_mailer.deliver"
    assert_contain ActiveSupport::Notifications.instrumenter.id[0..6]

    within Metric.first do
      click_link "Show"
    end

    assert_contain "active_record.sql"
    click_link "Back"

    within Metric.last do
      click_button "Destroy"
    end

    assert_not_contain "To"
    assert_contain "Metric \"action_mailer.deliver\" was destroyed with success"
  end
end
