require 'test_helper'

class MuteTest < ActiveSupport::TestCase
  include RailsMetrics::Mute

  setup do
    RailsMetrics.set_store { MockStore }
    MockStore.instances.clear
  end

  test "does not send an event during a mute! block" do
    mute_metrics! do
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
    RailsMetrics::Mute.mute_method!(notifier, :notify)

    notifier.new.notify
    wait
    assert MockStore.instances.empty?
  end
end
