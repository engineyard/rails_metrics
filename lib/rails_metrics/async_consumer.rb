require 'thread'

module RailsMetrics
  # An instrumenter that does not send notifications. This is used in the
  # AsyncQueue so saving events does not send any notifications, not even
  # for logging.
  class VoidInstrumenter < ::ActiveSupport::Notifications::Instrumenter
    def instrument(name, payload={})
      yield(payload) if block_given?
    end
  end

  class AsyncConsumer < ::Queue
    attr_reader :thread

    def initialize(&block)
      @block  = block
      @thread = Thread.new do
        set_void_instrumenter
        consume
      end
    end

  protected

    def set_void_instrumenter
      Thread.current[:"instrumentation_#{notifier.object_id}"] = VoidInstrumenter.new(notifier)
    end

    def notifier
      ActiveSupport::Notifications.notifier
    end

    def consume
      while args = shift
        @block.call(args)
      end
    end
  end    
end