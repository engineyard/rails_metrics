module RailsMetrics
  class MuteMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] =~ /^\/metrics/
        RailsMetrics.mute! do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end
