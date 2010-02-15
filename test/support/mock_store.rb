class ActiveSupport::TestCase
  class MockStore
    include RailsMetrics::Store

    attr_accessor :id, :name, :parent_id, :request_id, :started_at, :duration, :payload

    def self.instances
      @instances ||= []
    end

    def initialize
      self.class.instances << self
    end

    def kicked?
      @kicked || false
    end

    def new_record?
      true
    end

  protected

    def save_metric!
      self.id ||= (rand * 1000).to_i

      if self.name == "rails_metrics.kicker"
        @kicked = true
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end
end
