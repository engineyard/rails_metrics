class Metric < ActiveRecord::Base
  include RailsMetrics::Store

  Metric.establish_connection("metrics")
  RailsMetrics.mute_method!(self.connection, :log)

  validates_presence_of :name, :instrumenter_id, :duration, :started_at
  serialize :payload
end
