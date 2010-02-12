module RailsMetrics
  class Middleware
    include Mute

    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] =~ /^\/rails_metrics/
        mute_metrics! do
          @app.call(env)
        end
      else
        ActiveSupport::Notifications.instrument "rails_metrics.request",
          :path => env["PATH_INFO"], :method => env["REQUEST_METHOD"] do
          @app.call(env)
        end
      end
    end
  end
end