Thread.abort_on_exception = Rails.env.development? || Rails.env.test?

# TODO Allow metrics path to be configurable
require 'active_support/core_ext/module/delegation'

module RailsMetrics
  autoload :AsyncConsumer,    'rails_metrics/async_consumer'
  autoload :Mute,             'rails_metrics/mute'
  autoload :PayloadParser,    'rails_metrics/payload_parser'
  autoload :Store,            'rails_metrics/store'
  autoload :VERSION,          'rails_metrics/version'
  autoload :VoidInstrumenter, 'rails_metrics/async_consumer'

  module ORM
    autoload :ActiveRecord, 'rails_metrics/orm/active_record'
  end

  class << self
    delegate :mute!, :mute_instance_method!, :mute_class_method!, :to => RailsMetrics::Mute
  end

  # Set which store to use in RailsMetrics.
  #
  #   RailsMetrics.set_store { Metric }
  #
  def self.set_store(&block)
    metaclass.send :define_method, :store, &block
  end

  # Place holder for the store
  def self.store; end

  # Instantiate the store and call store!
  def self.store!(args)
    self.store.new.store!(args)
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
    @@async_consumer ||= AsyncConsumer.new { |args| RailsMetrics.store!(args) }
  end

  # Wait until the async queue is consumed.
  def self.wait
    sleep(0.05) until async_consumer.empty?
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

    RailsMetrics.store &&
    !RailsMetrics::Mute.blacklist.include?(instrumenter_id) &&
    !self.ignore_patterns.find { |p| String === p ? name == p : name =~ p } &&
    !self.ignore_lambdas.values.any? { |b| b.call(name, payload) }
  end
end

require 'rails_metrics/engine'