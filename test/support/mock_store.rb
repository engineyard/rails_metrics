class ActiveSupport::TestCase
  class MockStore
    attr_accessor :args

    def self.instances
      @instances ||= []
    end

    def initialize
      self.class.instances << self
    end

    def store!(args)
      @args = args

      if args[0] == "rails_metrics.kicker"
        args << :kicked!
        ActiveSupport::Notifications.instrument("rails_metrics.inside_store")
      end
    end
  end
end
