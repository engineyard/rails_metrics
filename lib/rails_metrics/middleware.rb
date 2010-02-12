module RailsMetrics
  class Middleware
    include Mute

    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] =~ /^\/rails_metrics/
        @app.call(env)
      else
        RailsMetrics.request_root_node = RailsMetrics::RootNode.new

        instrumenter.instrument "rails_metrics.request",
          :path => env["PATH_INFO"], :method => env["REQUEST_METHOD"],
          :instrumenter_id => instrumenter.id do
          @app.call(env)
        end
      end
    ensure
      RailsMetrics.request_root_node = nil
    end

  protected

    def instrumenter
      ActiveSupport::Notifications.instrumenter
    end
  end
end