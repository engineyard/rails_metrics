module RailsMetrics
  module Mute
    def mute_metrics!
      RailsMetrics::Mute.mute! { yield }
    end

    # Mute RailsMetrics subscriber during the block.
    def self.mute!
      self.blacklist << ActiveSupport::Notifications.instrumenter.id
      yield
    ensure
      self.blacklist.pop
    end

    # Mute a given method in a specified object.
    #
    #   RailsMetric::Mute.mute_method!(ActiveRecord::Base.connection, :log)
    #
    def self.mute_method!(object, method)
      object.class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{method}_with_mute!(*args, &block)
          RailsMetrics::Mute.mute!{ #{method}_without_mute!(*args, &block) }
        end
        alias_method_chain :#{method}, :mute!
      METHOD
    end

    # Keeps a blacklist of instrumenters ids.
    def self.blacklist
      Thread.current[:rails_metrics_blacklist] ||= []
    end

    class Middleware
      include Mute

      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] =~ /^\/metrics/
          mute_metrics! do
            @app.call(env)
          end
        else
          @app.call(env)
        end
      end
    end
  end
end