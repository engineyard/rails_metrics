require 'test_helper'

class NagivationTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
    get "/users"
    wait
  end

  test "can navigate all notifications" do
    get "/rails_metrics"
    click_link "All metrics"

    assert_contain "action_view.render_template"
    assert_contain "action_controller.process_action"
    assert_contain ActiveSupport::Notifications.instrumenter.id

    id = Metric.last.id

    within "#rails_metric_#{id}" do
      click_link "Show"
    end

    assert_contain "action_view.render_template"
    click_link "action_view.render_template"

    within "#rails_metric_#{id}" do
      click_button "Delete"
    end

    assert_contain "Metric ##{id} was deleted with success"

    get "/rails_metrics/all"
    assert_not_contain "action_view.render_template"
  end

  test "can nagivate all metrics with by scopes" do
    get "/rails_metrics/all"

    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_link "Remove \"Name\" filter"
    assert_contain "Showing 1 - 4 of 4 metrics"
  end

  test "can nagivate all metrics with order by scopes" do
    get "/rails_metrics/all"
    click_link "Order by latest"
    assert_contain "ordered by latest"

    click_link "Show"
    assert_contain "action_view.render_template"

    click_link "Back"
    click_link "Order by earliest"
    assert_contain "ordered by earliest"

    click_link "Show"
    assert_contain "rack.request"

    click_link "Back"
    click_link "Order by fastest"
    assert_contain "ordered by fastest"

    click_link "Show"
    assert_contain Metric.fastest.first.name
  end

  test "can destroy all notifications in a given scope" do
    get "/rails_metrics/all"
    click_link "active_record.sql"
    assert_contain "Showing 1 - 1 of 1 metrics filtered by name"

    click_button "Delete all"
    assert_contain "All 1 selected metrics were deleted."

    click_link "All metrics"
    assert_contain "Showing 1 - 3 of 3 metrics"
  end

  test "can navigate all metrics with pagination" do
    get "/rails_metrics/all"
    assert_contain "Showing 1 - 4 of 4 metrics"

    get "/rails_metrics/all?limit=2"
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
end
