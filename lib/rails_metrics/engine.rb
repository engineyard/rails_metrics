module RailsMetrics
  class Engine < ::Rails::Engine

    # Initialize configure parameters
    config.rails_metrics = ActiveSupport::OrderedOptions.new

    config.rails_metrics.ignore_lambdas  = {}
    config.rails_metrics.ignore_patterns = [ "action_controller.start_processing" ]

    initializer "rails_metrics.add_middleware" do |app|
      app.config.middleware.use RailsMetrics::Middleware
    end

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
      ActiveSupport::Notifications.subscribe /[^!]$/ do |*args|
        RailsMetrics.events.push(args) if RailsMetrics.valid_for_storing?(args)
      end
    end
  end
end
