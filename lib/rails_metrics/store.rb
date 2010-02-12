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

    def configure(args)
      self.name       = args[0].to_s
      self.started_at = args[1]
      self.duration   = (args[2] - args[1]) * 1000
      self.payload    = RailsMetrics::PayloadParser.filter(name, args[4])
    end

    def children
      @children ||= []
    end

    def parent_of?(node)
      start = (self.started_at - node.started_at) * 1000
      start <= 0 && (start + self.duration >= node.duration)
    end

    def child_of?(node)
      node.parent_of?(self)
    end

    def save_metrics!(parent_id=nil)
      self.instrumenter_id = parent_id
      save!

      children.each do |child|
        child.save_metrics!(self.id)
      end
    end
  end
end