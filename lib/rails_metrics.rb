Thread.abort_on_exception = Rails.env.development? || Rails.env.test?

module RailsMetrics
  # Keeps a link to the class which stores the metric. This is set automatically
  # when a module inherits from RailsMetrics::Store.
  mattr_accessor :store
  @@metrics_store = nil

  # Keeps a list of patterns to not be saved in the store. You can add how many
  # you wish:
  #
  #   RailsMetrics.ignored_patterns << /^action_controller/
  #
  mattr_accessor :ignored_patterns
  @@ignore_patterns = []

  # A notification is valid for storing if two conditions are met:
  #
  #   1) The instrumenter id which created the notification is not the same
  #      instrumenter id of this thread. This means that notifications generated
  #      inside this thread are stored in the database;
  #
  #   2) If the notification name does not match any ignored pattern;
  #
  # TODO Ignore notifications from /metrics
  def self.valid_for_storing?(name, instrumenter_id)
    ActiveSupport::Notifications.instrumenter.id != instrumenter_id &&
      !self.ignored_patterns.find { |regexp| name =~ regexp }
  end
end

# TODO Move me to Rails
ActiveSupport::Notifications.instrumenter.class_eval do
  attr_reader :id
end

# Subscribe to all notifications
ActiveSupport::Notifications.subscribe do |*args|
  RailsMetrics.store.new.store!(args) if RailsMetrics.valid_for_storing?(args[0].to_s, args[3])
end