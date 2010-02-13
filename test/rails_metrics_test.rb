require 'test_helper'

class RailsMetricsTest < ActiveSupport::TestCase
  setup do
    RailsMetrics.set_store { MockStore }
    MockStore.instances.clear
  end

  test "send instrumentation event to the specified store" do
    instrument "rails_metrics.something"
    wait
  
    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]
  end

  test "does not send an event to the store if it matches an ignored pattern" do
    RailsMetrics.ignore_patterns << /rails_metrics/
  
    begin
      instrument "rails_metrics.something"
      wait
      assert MockStore.instances.empty?
    ensure
      RailsMetrics.ignore_patterns.pop
    end
  end

  test "does not send an event to the store if it was generated inside it" do
    instrument "rails_metrics.kicker"
    wait

    assert_equal 1, MockStore.instances.size
    assert_equal "rails_metrics.kicker", MockStore.instances.last.args[0]
    assert MockStore.instances.last.kicked?
  end
end
