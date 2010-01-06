class Metric < ActiveRecord::Base
  include RailsMetrics::Store

  validates_presence_of :name, :instrumenter_id, :duration, :started_at
  serialize :payload
end
