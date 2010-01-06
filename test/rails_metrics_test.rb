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
    end
  end

  setup do
    MockStore.instances.clear
  end

  test "send instrumentation event to the specified store" do
    swap RailsMetrics, :store => MockStore do
      instrument "rails_metrics.something"
      wait

      mock_store = MockStore.instances.last
      assert_equal "rails_metrics.something", mock_store.args[0]
    end
  end
end
