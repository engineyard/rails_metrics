class ActiveSupport::TestCase
  class MockStore
    include RailsMetrics::Store

    attr_accessor :args, :id, :parent_id, :request_id

    def self.instances
      @instances ||= []
    end

    def initialize
      self.class.instances << self
    end

    def configure(args)
      @args = args
    end

    def kicked?
      @kicked || false
    end

  protected

    def save_metric!
      self.id = (rand * 1000).to_i

      if @args[0] == "rails_metrics.kicker"
        @kicked = true
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end
end
