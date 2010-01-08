require 'test_helper'

class AllMetricsTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
    wait
  end

  test "queries are added to RailsMetrics" do
    User.create!(:name => "User")
    wait!

    metric = Metric.last
    assert_equal "active_record.sql", metric.name
    assert_kind_of Integer, metric.duration
    assert (metric.duration >= 0)
    assert_kind_of Time, metric.started_at
    assert_match /INSERT INTO/, metric.payload[:sql]
  end

  # test "processed actions are added to RailsMetrics" do
  #   get "/users"
  #   metric = Metric.last
  # end
end
