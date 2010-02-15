require 'test_helper'

class InstrumentationTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
  end

  test "rails metrics request is added to notifications" do
    get "/users"
    wait

    request = Metric.first

    assert_equal "rack.request", request.name
    assert (request.duration >= 0)
    assert_kind_of Time, request.started_at
    assert_equal Hash[:path => "/users", :method => "GET",
      :instrumenter_id => ActiveSupport::Notifications.instrumenter.id], request.payload
  end

  test "processed actions are added to RailsMetrics" do
    get "/users"
    wait

    assert_equal 4, Metric.count
    request, action, sql, template = Metric.all

    assert_equal "action_controller.process_action", action.name
    assert_equal "active_record.sql", sql.name
    assert_equal "action_view.render_template", template.name

    assert (action.duration >= 0)
    assert (sql.duration >= 0)
    assert (template.duration >= 0)

    assert_kind_of Time, action.started_at
    assert_kind_of Time, sql.started_at
    assert_kind_of Time, template.started_at

    assert_equal Hash[:status=>200, :end_point=>"UsersController#index",
      :formats=>[:html]], action.payload

    assert_equal Hash[:sql => "SELECT `users`.* FROM `users`", 
      :name => "User Load"], sql.payload

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/users/index.html.erb",
      :layout => "RAILS_ROOT/app/views/layouts/users.html.erb"], template.payload
  end

  test "instrumentations are saved nested in the database" do
    get "/users"
    wait

    assert_equal 4, Metric.count
    request, action, sql, template = Metric.all

    assert_nil request.parent_id
    assert_equal action.parent_id, request.id
    assert_equal sql.parent_id, action.id
    assert_equal template.parent_id, action.id

    assert_equal request.id, request.request_id
    assert_equal request.id, action.request_id
    assert_equal request.id, sql.request_id
    assert_equal request.id, template.request_id
  end

  test "does not create metrics when accessing /rails_metrics" do
    assert_no_difference "Metric.count" do
      get "/rails_metrics"
      wait
    end
  end

  test "fragment cache are added to RailsMetrics" do
    get "/users/new"
    wait

    assert_equal 6, Metric.count
    request, action, template, partial, exist, write = Metric.all

    assert_equal "action_view.render_partial", partial.name
    assert_equal "action_controller.exist_fragment?", exist.name
    assert_equal "action_controller.write_fragment", write.name

    assert (partial.duration >= 0)
    assert (exist.duration >= 0)
    assert (write.duration >= 0)

    assert_kind_of Time, partial.started_at
    assert_kind_of Time, exist.started_at
    assert_kind_of Time, write.started_at

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/users/_form.html.erb"],
      partial.payload

    assert_equal Hash[:key => "views/foo.bar"], exist.payload
    assert_equal Hash[:key => "views/foo.bar"], write.payload
  end
end
