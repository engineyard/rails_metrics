require 'test_helper'

class RailsMetricsTest < ActiveSupport::TestCase
  class MockStore < ::MockStore
    def store!(args)
      super

      if args[0] == "rails_metrics.kicker"
        args << :kicked!
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end

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

  test "mutes a given method for a given class" do
    notifier = Class.new do
      def notify
        ActiveSupport::Notifications.instrument("rails_metrics.something")
      end
    end

    notifier.new.notify
    wait
    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]

    MockStore.instances.clear
    RailsMetrics.mute_method!(notifier, :notify)

    notifier.new.notify
    wait
    assert MockStore.instances.empty?
  end
end
