require 'active_support/core_ext/module/delegation'
Thread.abort_on_exception = Rails.env.development? || Rails.env.test?

module RailsMetrics
  autoload :AsyncConsumer,    'rails_metrics/async_consumer'
  autoload :Middleware,       'rails_metrics/middleware'
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

  def self.request_root_node
    Thread.current[:rails_metrics_request_root_node]
  end

  def self.request_root_node=(value)
    Thread.current[:rails_metrics_request_root_node] = value
  end

  class Node
    attr_reader :name, :started_at, :ended_at, :payload

    def initialize(name, started_at, ended_at, transaction_id, payload)
      @name       = name
      @started_at = started_at
      @ended_at   = ended_at
      @payload    = payload
      self
    end

    def root?
      false
    end

    def children
      @children ||= []
    end

    def duration
      @duration ||= 1000.0 * (@ended_at - @started_at)
    end

    def parent_of?(node)
      start = (self.started_at - node.started_at) * 1000
      start <= 0 && (start + self.duration >= node.duration)
    end

    def child_of?(node)
      node.parent_of?(self)
    end
  end

  class RootNode < Node
    alias :set_attributes! :initialize
    public :set_attributes!

    def initialize
    end

    def root?
      true
    end
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
    @@async_consumer ||= AsyncConsumer.new do |root_node|
      root_node.children.map! { |i| RailsMetrics::Node.new(*i) }

      nodes = root_node.children.dup
      root_node.children.clear
      nodes.push root_node

      while node = nodes.shift
        if parent = nodes.find { |n| n.parent_of?(node) }
          parent.children << node
        else
          raise "OMG, Node without parent #{node.inspect}" unless nodes.empty?
        end
      end

      save_nodes!(root_node)
    end
  end

  def self.save_nodes!(node, parent_id=nil)
    metric = RailsMetrics.store.new
    metric.store!([node.name, node.started_at, node.ended_at, parent_id, node.payload])
    parent_id = metric.id

    node.children.each do |child|
      save_nodes!(child, parent_id)
    end
  end

  # Wait until the async queue is consumed.
  def self.wait
    sleep(0.05) until async_consumer.finished?
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

    RailsMetrics.store && RailsMetrics.request_root_node &&
    !RailsMetrics::Mute.blacklist.include?(instrumenter_id) &&
    !self.ignore_patterns.find { |p| String === p ? name == p : name =~ p } &&
    !self.ignore_lambdas.values.any? { |b| b.call(name, payload) }
  end
end

require 'rails_metrics/engine'