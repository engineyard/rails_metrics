require 'test_helper'

class MuteMiddlewareTest < ActionController::IntegrationTest
  setup do
    Metric.delete_all
  end

  test "silences all metrics created in the /metrics path" do
    assert_no_difference "Metric.count" do
      get "/metrics"
      wait!
    end
  end
end
