# Setup to ignore any query which is not a SELECT, INSERT, UPDATE
# or DELETE and queries made by the own store.
RailsMetrics.ignore :invalid_queries do |name, payload|
  name == "data_mapper.sql" &&
    payload[:sql] !~ /^(SELECT|INSERT|UPDATE|DELETE)/
end

module RailsMetrics
  module ORM

    # Include in your model to store metrics. For DataMapper, you need the
    # following setup:
    #
    #   script/generate model Metric script/generate name:string duration:integer
    #     request_id:integer parent_id:integer payload:object started_at:datetime created_at:datetime --skip-timestamps
    #
    # You can use any model name you wish. Next, you need to include
    # RailsMetrics::ORM::DataMapper:
    #
    #   class Metric
    #     include DataMapper::Resource
    #     include RailsMetrics::ORM::DataMapper
    #   end
    #

    ORM.primary_key_finder = :get
    ORM.delete_all         = :destroy! # use bang version here cause we don't need no hooks

    ORM.metric_model_properties = %w[
      name:string
      duration:integer
      request_id:integer
      parent_id:integer
      payload:object
      started_at:datetime
      created_at:datetime
    ]

    def self.add_metric_model_config(generator, file_name, class_name)
      generator.inject_into_file "app/models/#{file_name}.rb",
        "  include RailsMetrics::ORM::DataMapper\n",
        {:after => "  include DataMapper::Resource\n"}
    end

    module DataMapper
      extend  ActiveSupport::Concern
      include RailsMetrics::Store

      included do
        # Set required validations
        validates_presence_of :name, :started_at, :duration
      end

      module ClassMethods

        # Select scopes

        def requests;                  all(:name       => 'rack.request') end
        def by_name(name);             all(:name       => name          ) end
        def by_request_id(request_id); all(:request_id => request_id    ) end

        # Order scopes
        # We need to add the id in the earliest and latest scope since the database
        # does not store miliseconds. The id then comes as second criteria, since
        # the ones started first are first saved in the database.

        def earliest; all(:order => [:started_at.asc,  :id.asc ]) end
        def latest;   all(:order => [:started_at.desc, :id.desc]) end
        def slowest;  all(:order => [:duration.desc            ]) end
        def fastest;  all(:order => [:duration.asc             ]) end

      end

      # Destroy all children if it's a request metric.
      def destroy
        self.class.by_request_id(self.id).destroy! if rack_request?
        super
      end

    protected

      def save_metric!
        save!
      end
      
    end
  end
end