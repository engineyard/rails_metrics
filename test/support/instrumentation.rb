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
    RailsMetrics.request_root_node = root_node = RailsMetrics::RootNode.new
    result = ActiveSupport::Notifications.instrument(*args, &block)
    RailsMetrics.async_consumer.push root_node
    result
  ensure
    RailsMetrics.request_root_node = nil
  end
end