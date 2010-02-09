require 'test_helper'

class ControllerTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
  end

  # Create two dummy notifications
  def create_metrics!(sleep=false)
    User.create!(:name => "User")
    sleep(1) if sleep
    Notification.welcome.deliver
    wait
  end

  test "can navigate notifications" do
    create_metrics!
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

    id = Metric.last.id
    within Metric.last do
      click_button "Delete"
    end

    assert_not_contain "To"
    assert_contain "Metric ##{id} was deleted with success"
  end

  test "can navigate with pagination" do
    create_metrics!

    get "/rails_metrics"
    assert_contain "Showing 1 - 3 of 3 metrics"

    get "/rails_metrics?limit=2"
    assert_contain "Showing 1 - 2 of 3 metrics"

    click_link "Next"
    assert_contain "Showing 3 - 3 of 3 metrics"

    assert_raise Webrat::NotFoundError do
      click_link "Next"
    end

    click_link "Previous"
    assert_contain "Showing 1 - 2 of 3 metrics"

    assert_raise Webrat::NotFoundError do
      click_link "Previous"
    end
  end

  test "can nagivate with by scopes" do
    create_metrics!
    get "/rails_metrics"

    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_link Metric.first.instrumenter_id
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name and instrumenter"

    click_link "Remove \"Name\" filter"
    assert_contain "Showing 1 - 3 of 3 metrics filtered by instrumenter"

    click_link "Remove \"Instrumenter\" filter"
    assert_contain "Showing 1 - 3 of 3 metrics"
  end

  test "can nagivate with order by scopes" do
    create_metrics!(true)

    get "/rails_metrics"
    click_link "Order by latest"
    assert_contain "ordered by latest"

    click_link "Show"
    assert_contain "action_view.render_template"

    get "/rails_metrics"
    click_link "Order by earliest"
    assert_contain "ordered by earliest"

    click_link "Show"
    assert_contain "active_record.sql"

    get "/rails_metrics"
    click_link "Order by fastest"
    assert_contain "ordered by fastest"

    click_link "Show"
    assert_contain Metric.fastest.first.name
  end

  test "can destroy all notifications in a given scope" do
    create_metrics!
    get "/rails_metrics"

    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_button "Delete all"
    assert_contain "All 1 selected metrics were deleted."
    assert_contain "Showing 1 - 2 of 2 metrics"
  end
end
