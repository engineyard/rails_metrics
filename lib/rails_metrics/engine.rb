module RailsMetrics
  class Engine < ::Rails::Engine
    engine_name :rails_metrics

    # Add middleware
    config.middleware.use RailsMetrics::Mute::Middleware

    # Initialize configure parameters
    config.rails_metrics.ignore_lambdas  = {}
    config.rails_metrics.ignore_patterns = [ "action_controller.start_processing" ]

    initializer "rails_metrics.set_ignores" do |app|
      RailsMetrics.ignore_lambdas.merge!(app.config.rails_metrics.ignore_lambdas)
      RailsMetrics.ignore_patterns.concat(app.config.rails_metrics.ignore_patterns)
    end

    initializer "rails_metrics.set_store" do |app|
      if app.config.rails_metrics.set_store
        RailsMetrics.set_store(&app.config.rails_metrics.set_store)
      end
    end

    initializer "rails_metrics.start_subscriber" do
      ActiveSupport::Notifications.subscribe do |*args|
        RailsMetrics.async_consumer.push(args) if RailsMetrics.valid_for_storing?(args)
      end
    end

    config.after_initialize do
      # Ensure the store is loaded right after initialization
      RailsMetrics.store
    end
  end
end