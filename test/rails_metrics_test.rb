require File.expand_path('test_helper', File.dirname(__FILE__))

class RailsMetricsTest < ActiveSupport::TestCase
  class MockStore
    attr_accessor :args

    def self.instances
      @instances ||= []
    end

    def initialize
      self.class.instances << self
    end

    def store!(args)
      @args = args

      if args[0] == "rails_metrics.kicker"
        args << :kicked!
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end

  setup do
    @_previous_store, RailsMetrics.store = RailsMetrics.store, MockStore
    MockStore.instances.clear
  end

  teardown do
    RailsMetrics.store = @_previous_store
  end

  test "send instrumentation event to the specified store" do
    instrument "rails_metrics.something"
    wait

    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]
  end

  test "does not send an event to the store if it matches an ignored pattern" do
    swap RailsMetrics, :ignore_patterns => [/rails_metrics/] do
      instrument "rails_metrics.something"
      wait

      assert MockStore.instances.empty?
    end
  end

  test "does not send an event to the store if it was generated inside it" do
    instrument "rails_metrics.kicker"
    wait

    assert_equal 1, MockStore.instances.size
    assert_equal :kicked!, MockStore.instances.last.args.last
    assert_equal "rails_metrics.kicker", MockStore.instances.last.args[0]
  end

  test "does not send an event during a mute! block" do
    RailsMetrics.mute! do
      instrument "rails_metrics.something"
      wait
      assert MockStore.instances.empty?
    end

    instrument "rails_metrics.something"
    wait
    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]
  end
end
