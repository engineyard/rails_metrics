Thread.abort_on_exception = Rails.env.development? || Rails.env.test?

# TODO Handle multiple environments
# TODO Allow metrics path to be configurable

module RailsMetrics
  autoload :MuteMiddleware, 'rails_metrics/mute_middleware'
  autoload :PayloadParser,  'rails_metrics/payload_parser'
  autoload :Store,          'rails_metrics/store'
  autoload :VERSION,        'rails_metrics/version'

  # Keeps a link to the class which stores the metric. This is set automatically
  # when a module inherits from RailsMetrics::Store.
  mattr_accessor :store
  @@metrics_store = nil

  # Keeps a list of patterns to not be saved in the store. You can add how many
  # you wish:
  #
  #   RailsMetrics.ignore_patterns << /^action_controller/
  #
  mattr_accessor :ignore_patterns
  @@ignore_patterns = []

  # A notification is valid for storing if two conditions are met:
  #
  #   1) The instrumenter id which created the notification is not the same
  #      instrumenter id of this thread. This means that notifications generated
  #      inside this thread are stored in the database;
  #
  #   2) If the notification name does not match any ignored pattern;
  #
  def self.valid_for_storing?(name, instrumenter_id)
    ActiveSupport::Notifications.instrumenter.id != instrumenter_id &&
      !RailsMetrics.blacklist.include?(instrumenter_id) &&
      !self.ignore_patterns.find { |regexp| name =~ regexp }
  end

  # Mute RailsMetrics subscriber during the block.
  def self.mute!
    ActiveSupport::Notifications.instrument("rails_metrics.add_to_blacklist")
    yield
  ensure
    ActiveSupport::Notifications.instrument("rails_metrics.remove_from_blacklist")
  end

  # Mute the given method in the specified object.
  def self.mute_method!(object, method)
    object.class_eval <<-METHOD, __FILE__, __LINE__ + 1
      def #{method}_with_mute!(*args, &block)
        RailsMetrics.mute!{ #{method}_without_mute!(*args, &block) }
      end
      alias_method_chain :#{method}, :mute!
    METHOD
  end

  # Contains the actual storing logic, compatible with RailsMetrics::Store API.
  # Overwrite at will.
  def self.store!(args)
    self.store.new.store!(args)
  end

  # Keeps a blacklist of instrumenters ids.
  def self.blacklist
    Thread.current[:rails_metrics_blacklist] ||= []
  end
end

# Configure middleware
Rails.application.config.middleware.use RailsMetrics::MuteMiddleware

# Configure subscriptions
ActiveSupport::Notifications.subscribe do |*args|
  name, instrumenter_id = args[0].to_s, args[3]

  if args[0] == "rails_metrics.add_to_blacklist"
    RailsMetrics.blacklist << instrumenter_id
  elsif args[0] == "rails_metrics.remove_from_blacklist"
    RailsMetrics.blacklist.pop
  elsif RailsMetrics.valid_for_storing?(name, instrumenter_id)
    RailsMetrics.store!(args)
  end
end