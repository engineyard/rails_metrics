# TODO Allow metrics path to be configurable
# TODO Push database writes to an Async Queue

module RailsMetrics
  autoload :MuteMiddleware, 'rails_metrics/mute_middleware'
  autoload :PayloadParser,  'rails_metrics/payload_parser'
  autoload :Store,          'rails_metrics/store'
  autoload :VERSION,        'rails_metrics/version'

  module ORM
    autoload :ActiveRecord, 'rails_metrics/orm/active_record'
  end

  mattr_accessor :ignore_patterns
  @@ignore_patterns = []

  # Set which store to use in RailsMetrics.
  #
  #   RailsMetrics.set_store { Metric }
  #
  def self.set_store(&block)
    metaclass.send :define_method, :store, &block
  end

  # Allow you to specify a condition to ignore a notification based
  # on its name and/or payload. For example, if you want to ignore
  # all notifications with empty payload, one can do:
  #
  #   RailsMetrics.ignore :with_empty_payload do |name, payload|
  #     payload.empty?
  #   end
  #
  # However, if you want to ignore something based solely on its
  # name, you can use ignore_patterns instead:
  #
  #   RailsMetrics.ignore_patterns << /^some_noise_plugin/
  #
  def self.ignore(name, &block)
    raise ArgumentError, "ignore expects a block" unless block_given?
    ignore_lambdas[name] = block
  end

  # Stroes the blocks given to ignore with their respective identifier
  # in a hash.
  def self.ignore_lambdas #:nodoc:
    @@ignore_lambdas ||= {}
  end

  # A notification is valid for storing if two conditions are met:
  #
  #   1) The instrumenter id which created the notification is not the same
  #      instrumenter id of this thread. This means that notifications generated
  #      inside this thread are stored in the database;
  #
  #   2) If the notification name does not match any ignored pattern;
  #
  def self.valid_for_storing?(args) #:nodoc:
    name, instrumenter_id, payload = args[0].to_s, args[3], args[4]

    !(RailsMetrics.blacklist.include?(instrumenter_id) ||
    self.ignore_patterns.find { |p| String === p ? name == p : name =~ p } ||
    self.ignore_lambdas.values.any? { |b| b.call(name, payload) })
  end

  # Mute RailsMetrics subscriber during the block.
  def self.mute!
    RailsMetrics.blacklist << ActiveSupport::Notifications.instrumenter.id
    yield
  ensure
    RailsMetrics.blacklist.pop
  end

  # Mute a given method in a specified object.
  #
  #   RailsMetric.mute!(ActiveRecord::Base.connection, :log)
  #
  def self.mute_method!(object, method)
    object.class_eval <<-METHOD, __FILE__, __LINE__ + 1
      def #{method}_with_mute!(*args, &block)
        RailsMetrics.mute!{ #{method}_without_mute!(*args, &block) }
      end
      alias_method_chain :#{method}, :mute!
    METHOD
  end

  # Instantiate the store and call store!
  def self.store!(args)
    self.store.new.store!(args)
  end

  # Keeps a blacklist of instrumenters ids.
  def self.blacklist
    Thread.current[:rails_metrics_blacklist] ||= []
  end
end

Rails.application.config.middleware.use RailsMetrics::MuteMiddleware
RailsMetrics.ignore_patterns << "action_controller.start_processing"

ActiveSupport::Notifications.subscribe do |*args|
  if RailsMetrics.valid_for_storing?(args)
    RailsMetrics.mute! do
      RailsMetrics.store!(args)
    end
  end
end