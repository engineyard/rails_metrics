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
      @mutex = Mutex.new

      @thread = Thread.new do
        set_void_instrumenter
        consume
      end
    end

    def push(*args)
      @mutex.synchronize { @off = false }
      @queue.push(*args)
    end

    def finished?
      @off
    end

  protected

    def set_void_instrumenter #:nodoc:
      Thread.current[:"instrumentation_#{notifier.object_id}"] = VoidInstrumenter.new(notifier)
    end

    def notifier #:nodoc:
      ActiveSupport::Notifications.notifier
    end

    def consume #:nodoc:
      while args = @queue.shift
        @block.call(args)
        @mutex.synchronize { @off = @queue.empty? }
      end
    end
  end
end