module RailsMetrics
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] =~ /^\/rails_metrics/
        @app.call(env)
      else
        RailsMetrics.listen_request do
          response = notifications.instrument "rack.request",
            :path => env["PATH_INFO"], :method => env["REQUEST_METHOD"],
            :instrumenter_id => notifications.instrumenter.id do
            @app.call(env)
          end
        end
      end
    end

  protected

    def notifications
      ActiveSupport::Notifications
    end
  end
end