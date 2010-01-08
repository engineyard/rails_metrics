module RailsMetrics
  # Include in your model to store metrics. For ActiveRecord, you need the
  # following setup:
  #
  #   script/generate model Metric script/generate name:string duration:integer
  #     instrumenter_id:string payload:text started_at:datetime created_at:datetime --skip-timestamps
  #
  # You can use any name you wish. Next, you need to include RailsMetrics::Store
  # and set the payload as a serializable attribute:
  #
  #   class Metric < ActiveRecord::Base
  #     include RailsMetrics::Store
  #
  #     validates_presence_of :name, :transaction_id, :duration, :started_at
  #     serialize :payload
  #   end
  #
  module Store
    def self.included(base)
      RailsMetrics.store ||= base
    end

    def store!(args)
      self.name            = args[0].to_s
      self.started_at      = args[1]
      self.duration        = (args[2] - args[1]) * 1000
      self.instrumenter_id = args[3]
      self.payload         = RailsMetrics::PayloadParser.filter(name, args[4])

      save_metrics!
      self
    end

    def save_metrics!
      save!
    end
  end
end