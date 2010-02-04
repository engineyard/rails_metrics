require 'test_helper'

class AllMetricsTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
  end

  test "queries are added to RailsMetrics" do
    User.create!(:name => "User")
    wait!

    assert_equal 1, Metric.count
    metric = Metric.first

    assert_equal "active_record.sql", metric.name
    assert (metric.duration >= 0)
    assert_kind_of Time, metric.started_at
    assert_match /INSERT INTO/, metric.payload[:sql]
  end

  test "processed actions are added to RailsMetrics" do
    get "/users"
    wait!

    assert_equal 3, Metric.count
    sql, template, action = Metric.all

    assert_equal "action_view.render_template", template.name
    assert_equal "action_controller.process_action", action.name

    assert (template.duration >= 0)
    assert (action.duration >= 0)

    assert_kind_of Time, template.started_at
    assert_kind_of Time, action.started_at

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/users/index.html.erb",
      :layout => "RAILS_ROOT/app/views/layouts/users.html.erb"], template.payload

    assert_equal Hash[:formats => [:html], :controller => "UsersController", :method => :get,
      :action => "index", :path => "/users", :status => 200], action.payload.except(:db_runtime, :view_runtime)
  end

  test "mailer deliveries are added to RailsMetrics" do
    message = Notification.welcome.deliver
    wait!

    assert_equal 2, Metric.count
    template, mail = Metric.all

    assert_equal "action_view.render_template", template.name
    assert_equal "action_mailer.deliver", mail.name

    assert (template.duration >= 0)
    assert (mail.duration >= 0)

    assert_kind_of Time, template.started_at
    assert_kind_of Time, mail.started_at

    assert_equal Hash[:identifier => "RAILS_ROOT/app/views/notification/welcome.erb"],
      template.payload

    assert_equal Hash[:subject => "Welcome", :from => ["sender@rails-metrics-app.com"],
       :message_id => nil, :to => ["destination@rails-metrics-app.com"],
       :mailer => "Notification", :date => message.date], mail.payload
  end

  test "fragment cache are added to RailsMetrics" do
    get "users/new"
    wait!

    assert_equal 5, Metric.count
    partial, exist, write, = Metric.all

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
