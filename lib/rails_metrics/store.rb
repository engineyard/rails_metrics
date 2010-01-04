module RailsMetrics
  # Include in your model to store metrics. For ActiveRecord, you need to set
  # the payload as a serializable attribute:
  #
  #   class Metrics < ActiveRecord::Base
  #     include RailsMetrics::Store
  #
  #     validates_presence_of :name, :transaction_id, :duration, :started_at
  #     serialize :payload
  #   end
  #
  # You will also need the following migration:
  #
  #   create_table :metrics do |t|
  #     t.string :name
  #     t.string :transaction_id
  #     t.integer :duration
  #     t.text :payload
  #     t.datetime :started_at
  #     t.datetime :created_at
  #   end
  #
  module Store
    def self.included(base)
      RailsMetrics.store ||= base
    end

    def store!(args)
      self.name           = args[0].to_s
      self.started_at     = args[1]
      self.duration       = (args[2] - args[1]) * 1000
      self.transaction_id = args[3]
      self.payload        = RailsMetrics::PayloadParser.filter(name, args[4])

      save_metrics!
    end

    def save_metrics!
      save!
    end
  end
end