class ActiveSupport::TestCase
  def wait
    RailsMetrics.wait
  end

  def instrument(*args, &block)
    if RailsMetrics.listening?
      ActiveSupport::Notifications.instrument(*args, &block)
    else
      RailsMetrics.listen do
        ActiveSupport::Notifications.instrument(*args, &block)
      end
    end
  end
end