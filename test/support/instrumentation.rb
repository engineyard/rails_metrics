class ActiveSupport::TestCase
  def wait
    RailsMetrics.wait
  end

  # Fake a request instrumentation.
  def instrument(*args, &block)
    if RailsMetrics.listening?
      ActiveSupport::Notifications.instrument(*args, &block)
    else
      RailsMetrics.listen_request do
        ActiveSupport::Notifications.instrument "rack.request" do
          ActiveSupport::Notifications.instrument(*args, &block)
        end
      end
    end
  end
end