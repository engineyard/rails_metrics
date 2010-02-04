# Mute migration notifications.
RailsMetrics.mute_method! ActiveRecord::Migrator, :migrate

# Setup to ignore any query which is not a SELECT, INSERT, UPDATE
# or DELETE and queries made by the own store.
RailsMetrics.ignore :invalid_queries do |name, payload|
  name == "active_record.sql" &&
    (payload[:sql] !~ /^(SELECT|INSERT|UPDATE|DELETE)/ ||
    RailsMetrics.store.connections_ids.include?(payload[:connection_id]))
end

module RailsMetrics
  module ORM
    # Include in your model to store metrics. For ActiveRecord, you need the
    # following setup:
    #
    #   script/generate model Metric script/generate name:string duration:integer
    #     instrumenter_id:string payload:text started_at:datetime created_at:datetime --skip-timestamps
    #
    # You can use any model name you wish. Next, you need to include
    # RailsMetrics::ORM::ActiveRecord:
    #
    #   class Metric < ActiveRecord::Base
    #     include RailsMetrics::ORM::ActiveRecord
    #   end
    #
    module ActiveRecord
      extend  ActiveSupport::Concern
      include RailsMetrics::Store

      included do
        # Create a new connection pool just for the given resource
        establish_connection(Rails.env)

        # Set required validations
        validates_presence_of :name, :instrumenter_id, :duration, :started_at

        # Serialize payload data
        serialize :payload
      end

      module ClassMethods
        def connections_ids
          self.connection_pool.connections.map(&:object_id)
        end
      end

    protected

      def save_metrics!
        save!
      end
    end
  end
end