class ActiveSupport::TestCase
  def wait
    RailsMetrics.wait
  end

  # Sometimes we need to wait until RailsMetrics push reaches the Queue.
  def wait!
    sleep(0.05)
    wait
  end

  def instrument(*args, &block)
    ActiveSupport::Notifications.instrument(*args, &block)
  end
end