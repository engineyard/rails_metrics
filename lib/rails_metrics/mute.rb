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
    #   RailsMetric::Mute.mute_instance_method!(ActiveRecord::Base.connection, :log)
    #
    def self.mute_instance_method!(object, method)
      object.class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{method}_with_mute!(*args, &block)
          RailsMetrics::Mute.mute!{ #{method}_without_mute!(*args, &block) }
        end
        alias_method_chain :#{method}, :mute!
      METHOD
    end

    # The same as mute_instance_method!, but mutes a class method.
    def self.mute_class_method!(object, method)
      mute_instance_method!(object.metaclass, method)
    end

    # Keeps a blacklist of instrumenters ids.
    def self.blacklist
      Thread.current[:rails_metrics_blacklist] ||= []
    end
  end
end