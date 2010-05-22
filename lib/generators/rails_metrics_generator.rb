class RailsMetricsGenerator < Rails::Generators::NamedBase
  class_option :migration, :type => :boolean, :default => true

  class_option :update, :type => :boolean, :default => false,
                        :desc => "Just update public files, do not create a model"

  def self.source_root
    @_metrics_source_root ||= File.dirname(__FILE__)
  end

  def copy_public_files
    directory "../../public", "public", :recursive => true
    exit(0) if options.update?
  end

  def invoke_model
    require "rails_metrics/orm/#{Rails::Generators.options[:rails][:orm]}"
    invoke "model", [name].concat(RailsMetrics::ORM.metric_model_properties),
      :timestamps => false, :test_framework => false, :migration => options.migration?
  end

  def add_model_config
    RailsMetrics::ORM.add_metric_model_config(self, file_name, class_name)
  end

  def add_application_config
    inject_into_class "config/application.rb", "Application", <<-CONTENT
    # Set rails metrics store
    config.rails_metrics.set_store = lambda { ::#{class_name} }

CONTENT
  end
end
