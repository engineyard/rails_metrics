class Metric < ActiveRecord::Base
  include RailsMetrics::Store

  # Create a new connection pool just for Metric
  Metric.establish_connection(Rails.env)

  validates_presence_of :name, :instrumenter_id, :duration, :started_at
  serialize :payload
end
