class Metric < ActiveRecord::Base
  include RailsMetrics::Store

  # Ensure that Metric has a different connection than ActiveRecord::Base
  Metric.establish_connection(Rails.env)
  RailsMetrics.mute_method!(self.connection, :log)

  if ActiveRecord::Base.connection.methods.map(&:to_sym).include?(:log_with_mute!)
    raise "ActiveRecord::Base.connection is being muted. This is probably because #{self.class.name} " << 
          "has the same connection as ActiveRecord::Base. Could not use RailsMetrics."
  end

  validates_presence_of :name, :instrumenter_id, :duration, :started_at
  serialize :payload
end
