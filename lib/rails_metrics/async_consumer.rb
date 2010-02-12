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

  class AsyncConsumer
    attr_reader :thread

    def initialize(queue=Queue.new, &block)
      @off   = true
      @block = block
      @queue = queue

      @thread = Thread.new do
        set_void_instrumenter
        consume
      end
    end

    def push(*args)
      @queue.push(*args)
    end

    def finished?
      @queue.empty? && @off
    end

  protected

    def set_void_instrumenter
      Thread.current[:"instrumentation_#{notifier.object_id}"] = VoidInstrumenter.new(notifier)
    end

    def notifier
      ActiveSupport::Notifications.notifier
    end

    def consume
      while args = @queue.shift
        @off = false
        @block.call(args)
        @off = true
      end
    end
  end    
end