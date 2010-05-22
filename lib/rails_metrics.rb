require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute'

Thread.abort_on_exception = Rails.env.development? || Rails.env.test?

module RailsMetrics
  autoload :AsyncConsumer,    'rails_metrics/async_consumer'
  autoload :Middleware,       'rails_metrics/middleware'
  autoload :PayloadParser,    'rails_metrics/payload_parser'
  autoload :Store,            'rails_metrics/store'
  autoload :VERSION,          'rails_metrics/version'
  autoload :VoidInstrumenter, 'rails_metrics/async_consumer'

  module ORM
    autoload :ActiveRecord, 'rails_metrics/orm/active_record'
    autoload :DataMapper,   'rails_metrics/orm/data_mapper'

    class << self
      class_attribute :primary_key_finder
      class_attribute :delete_all
      class_attribute :metric_model_properties
    end
  end

  # Set which store to use in RailsMetrics.
  #
  #   RailsMetrics.set_store { Metric }
  #
  def self.set_store(&block)
    singleton_class.send :define_method, :store, &block
  end

  # Place holder for the store.
  def self.store; end

  # Holds the events for a specific thread.
  def self.events
    Thread.current[:rails_metrics_events] ||= []
  end

  # Turn RailsMetrics on, i.e. make it listen to notifications during the block.
  # At the end, it pushes notifications to the async consumer.
  def self.listen_request
    events = RailsMetrics.events
    events.clear

    Thread.current[:rails_metrics_listening] = true
    result = yield

    RailsMetrics.async_consumer.push(events.dup)
    result
  ensure
    Thread.current[:rails_metrics_listening] = false
    RailsMetrics.events.clear
  end

  # Returns if events are being registered or not.
  def self.listening?
    Thread.current[:rails_metrics_listening] || false
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

  # Stores the blocks given to ignore with their respective identifier in a hash.
  def self.ignore_lambdas
    @@ignore_lambdas ||= {}
  end

  # Stores ignore patterns that can be given as strings or regexps.
  def self.ignore_patterns
    @@ignore_patterns ||= []
  end

  # Holds the queue which store stuff in the database.
  def self.async_consumer
    @@async_consumer ||= AsyncConsumer.new do |events|
      next if events.empty?
      root = RailsMetrics.store.events_to_metrics_tree(events)
      root.save_metrics!
    end
  end

  # Wait until the async queue is consumed.
  def self.wait
    sleep(0.01) until async_consumer.finished?
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
    name, payload = args[0].to_s, args[4]

    RailsMetrics.listening? && RailsMetrics.store &&
    !self.ignore_patterns.find { |p| String === p ? name == p : name =~ p } &&
    !self.ignore_lambdas.values.any? { |b| b.call(name, payload) }
  end
end

require 'rails_metrics/engine'
