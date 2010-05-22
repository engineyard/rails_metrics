# Setup to ignore any query which is not a SELECT, INSERT, UPDATE
# or DELETE and queries made by the own store.
RailsMetrics.ignore :invalid_queries do |name, payload|
  name == "active_record.sql" &&
    payload[:sql] !~ /^(SELECT|INSERT|UPDATE|DELETE)/
end

module RailsMetrics
  module ORM
    # Include in your model to store metrics. For ActiveRecord, you need the
    # following setup:
    #
    #   script/generate model Metric script/generate name:string duration:integer
    #     request_id:integer parent_id:integer payload:text started_at:datetime created_at:datetime --skip-timestamps
    #
    # You can use any model name you wish. Next, you need to include
    # RailsMetrics::ORM::ActiveRecord:
    #
    #   class Metric < ActiveRecord::Base
    #     include RailsMetrics::ORM::ActiveRecord
    #   end
    #

    ORM.primary_key_finder = :find
    ORM.delete_all         = :delete_all

    ORM.metric_model_properties = %w[
      name:string
      duration:integer
      request_id:integer
      parent_id:integer
      payload:text
      started_at:datetime
      created_at:datetime
    ]

    def self.add_metric_model_config(generator, file_name, class_name)
      generator.inject_into_class "app/models/#{file_name}.rb", class_name, <<-CONTENT
        include RailsMetrics::ORM::#{Rails::Generators.options[:rails][:orm].to_s.camelize}
      CONTENT
    end

    module ActiveRecord
      extend  ActiveSupport::Concern
      include RailsMetrics::Store

      included do
        # Create a new connection pool just for the given resource
        establish_connection(Rails.env)

        # Set required validations
        validates_presence_of :name, :started_at, :duration

        # Serialize payload data
        serialize :payload

        # Select scopes
        scope :requests,      where(:name => "rack.request")
        scope :by_name,       lambda { |name| where(:name => name) }
        scope :by_request_id, lambda { |request_id| where(:request_id => request_id) }

        # Order scopes
        # We need to add the id in the earliest and latest scope since the database
        # does not store miliseconds. The id then comes as second criteria, since
        # the ones started first are first saved in the database.
        scope :earliest, order("started_at ASC, id ASC")
        scope :latest,   order("started_at DESC, id DESC")
        scope :slowest,  order("duration DESC")
        scope :fastest,  order("duration ASC")
      end

    protected

      def save_metric!
        save!
      end
    end
  end
end