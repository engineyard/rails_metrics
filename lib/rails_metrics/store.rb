module RailsMetrics
  # This module contains the default API for storing notifications.
  # Imagine that you configure your store to be the Metric class:
  #
  #   RailsMetrics.set_store { Metric }
  #
  # Whenever a notification comes, RailsMetrics instantiates a new
  # store and call configure on it with the instrumentation arguments:
  #
  #   metric = Metric.new
  #   metric.configure(args)
  #   metric
  #
  # After all metrics are configured they are nested and save_metrics! is called,
  # where each metric saves itself and its children.
  #
  # The method save_metrics! is implemented below and it requires the method
  # save_metric! to be implemented in the target class.
  #
  module Store
    VALID_ORDERS = %w(earliest latest slowest fastest).freeze
    extend ActiveSupport::Concern

    module ClassMethods
      def mount_tree(metrics)
        while metric = metrics.shift
          if parent = metrics.find { |n| n.parent_of?(metric) }
            parent.children << metric
          elsif metrics.empty?
            return metric if metric.rack_request?
            raise %(Expected tree root to be a "rack.request", got #{metric.name.inspect})
          end
        end
      end

      def events_to_metrics_tree(events)
        verify_active_connections! if respond_to?(:verify_active_connections!)

        metrics = events.map do |event|
          metric = new
          metric.configure(event)
          metric
        end

        mount_tree(metrics)
      end
    end

    # Configure the current metric by setting the values yielded by
    # the instrumentation event.
    def configure(args)
      self.payload    = RailsMetrics::PayloadParser.filter(name, args[4])
      self.name       = args[0].to_s
      self.started_at = args[1]
      self.duration   = normalized_duration(self.payload, args)
    end

    def duration_in_us
      self.duration
    end

    def duration_in_ms
      self.duration * 0.001
    end

    def exclusive_duration
      @exclusive_duration ||= self.duration - children.sum(&:duration)
    end

    def exclusive_duration_in_us
      self.exclusive_duration
    end

    def exclusive_duration_in_ms
      self.exclusive_duration * 0.001
    end

    # Stores the children of this metric when a tree is created.
    def children
      @children ||= []
    end

    def rack_request?
      self.name == "rack.request"
    end

    # Returns if the current node is the parent of the given node.
    # If this is a new record, we can use started_at values to detect parenting.
    # However, if it was already saved, we lose microseconds information from
    # timestamps and we must rely solely in id and parent_id information.
    def parent_of?(node)
      if !persisted?
        start = (self.started_at - node.started_at) * 1000000
        start <= 0 && (start + self.duration >= node.duration)
      else
        self.id == node.parent_id
      end
    end

    def child_of?(node)
      node.parent_of?(self)
    end

    # Save the current metric and all of its children by properly setting
    # the request and parent ids.
    def save_metrics!(request_id=nil, parent_id=nil)
      self.request_id, self.parent_id = request_id, parent_id
      save_metric!

      children.each do |child|
        child.save_metrics!(request_id || self.id, self.id)
      end

      unless self.request_id
        self.request_id ||= self.id
        save_metric!
      end
    end

    # Destroy all children if it's a request metric.
    def destroy
      self.class.by_request_id(self.id).delete_all if rack_request?
      super
    end

  protected

    def save_metric!
      raise NotImplementedError
    end

    def normalized_duration(payload, args)
      payload[:duration] ? payload[:duration] : (args[2] - args[1]) * 1000000
    end

  end
end
