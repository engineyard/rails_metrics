require 'test_helper'

class AllMetricsTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
    wait
  end

  test "queries are added to RailsMetrics" do
    User.create!(:name => "User")
    wait! # For some reason, we need to wait the publishing propragate

    metric = Metric.last
    assert_equal "active_record.sql", metric.name
    assert (metric.duration >= 0)
    assert_kind_of Time, metric.started_at
    assert_match /INSERT INTO/, metric.payload[:sql]
  end

  test "processed actions are added to RailsMetrics" do
    get "/users"
    wait

    assert_equal 4, Metric.count
    sql, template, layout, action = Metric.all

    assert_equal "action_view.render_template", template.name
    assert_equal "action_view.render_layout", layout.name
    assert_equal "action_controller.process_action", action.name

    assert (template.duration >= 0)
    assert (layout.duration >= 0)
    assert (action.duration >= 0)

    assert_kind_of Time, template.started_at
    assert_kind_of Time, layout.started_at
    assert_kind_of Time, action.started_at

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/users/index.html.erb",
      :layout => "RAILS_ROOT/app/views/layouts/users.html.erb"], template.payload

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/layouts/users.html.erb"],
      layout.payload

    assert_equal Hash[:formats => [Mime::HTML], :controller => "users", :method => :get,
      :action => "index"], action.payload
  end
end
