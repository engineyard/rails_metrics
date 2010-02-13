class ActiveSupport::TestCase
  def wait
    RailsMetrics.wait
  end

  def instrument(*args, &block)
    RailsMetrics.listen do
      ActiveSupport::Notifications.instrument(*args, &block)
    end
  end
end