require 'test_helper'

class NagivationTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
  end

  test "can navigate notifications" do
    get "/users" # set up metrics
    get "/rails_metrics"

    assert_contain "action_view.render_template"
    assert_contain "action_controller.process_action"
    assert_contain ActiveSupport::Notifications.instrumenter.id

    id = Metric.last.id

    within Metric.last do
      click_link "Show"
    end

    assert_contain "action_view.render_template"
    click_link "Back"

    within Metric.last do
      click_button "Delete"
    end

    assert_not_contain "action_view.render_template"
    assert_contain "Metric ##{id} was deleted with success"
  end

  test "can navigate with pagination" do
    get "/users" # set up metrics

    get "/rails_metrics"
    assert_contain "Showing 1 - 4 of 4 metrics"

    get "/rails_metrics?limit=2"
    assert_contain "Showing 1 - 2 of 4 metrics"

    click_link "Next"
    assert_contain "Showing 3 - 4 of 4 metrics"

    assert_raise Webrat::NotFoundError do
      click_link "Next"
    end

    click_link "Previous"
    assert_contain "Showing 1 - 2 of 4 metrics"

    assert_raise Webrat::NotFoundError do
      click_link "Previous"
    end
  end

  test "can nagivate with by scopes" do
    get "/users" # set up metrics
    get "/rails_metrics"

    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_link "Remove \"Name\" filter"
    assert_contain "Showing 1 - 4 of 4 metrics"
  end

  test "can nagivate with order by scopes" do
    get "/users" # set up metrics

    get "/rails_metrics"
    click_link "Order by latest"
    assert_contain "ordered by latest"

    click_link "Show"
    assert_contain "action_view.render_template"

    get "/rails_metrics"
    click_link "Order by earliest"
    assert_contain "ordered by earliest"

    click_link "Show"
    assert_contain "rails_metrics.request"

    get "/rails_metrics"
    click_link "Order by fastest"
    assert_contain "ordered by fastest"

    click_link "Show"
    assert_contain Metric.fastest.first.name
  end

  test "can destroy all notifications in a given scope" do
    get "/users" # set up metrics
    get "/rails_metrics"

    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_button "Delete all"
    assert_contain "All 1 selected metrics were deleted."
    assert_contain "Showing 1 - 3 of 3 metrics"
  end
end
