module RailsMetrics
  # This module contains the default API for storing notifications.
  # Imagine that you configure your store to be the Metric class:
  #
  #   RailsMetrics.set_store { Metric }
  #
  # Whenever a notification comes, RailsMetrics instantiates a new
  # store and call store! on it with the instrumentation arguments:
  #
  #   Metric.new.store!(args)
  #
  # The method store! is implemented below and it requires the method
  # save_metric! to be implemented in the target class.
  #
  module Store
    VALID_ORDERS = %w(earliest latest slowest fastest).freeze

    def store!(args)
      self.name            = args[0].to_s
      self.started_at      = args[1]
      self.duration        = (args[2] - args[1]) * 1000
      self.instrumenter_id = args[3]
      self.payload         = RailsMetrics::PayloadParser.filter(name, args[4])

      save_metrics!
      self
    end

  protected

    def save_metrics!
      raise NotImplementedError
    end
  end
end