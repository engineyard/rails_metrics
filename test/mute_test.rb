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

  test "mutes a given instance method for a given class" do
    notifier = Class.new do
      def notify
        ActiveSupport::Notifications.instrument("rails_metrics.something")
      end
    end

    notifier.new.notify
    wait
    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]

    MockStore.instances.clear
    RailsMetrics.mute_instance_method!(notifier, :notify)

    notifier.new.notify
    wait
    assert MockStore.instances.empty?
  end

  test "mutes a given class method for a given class" do
    notifier = Class.new do
      def self.notify
        ActiveSupport::Notifications.instrument("rails_metrics.something")
      end
    end

    notifier.notify
    wait
    assert_equal "rails_metrics.something", MockStore.instances.last.args[0]

    MockStore.instances.clear
    RailsMetrics.mute_class_method!(notifier, :notify)

    notifier.notify
    wait
    assert MockStore.instances.empty?
  end

end
