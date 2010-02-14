module RailsMetrics
  # ActiveSupport::Notifications usually comes with extra information as the
  # SQL query, response status and many others. This information is called payload.
  #
  # By default, RailsMetrics stores the whole payload in the database but it allows
  # you to manipulate it or even ignore some through the add and ignore methods.
  #
  # For example, "activerecord.sql" has as paylaod a hash with :name (like "Product
  # Load"), the :sql to be performed and the :connection_id. We can remove the connection
  # from the hash by simply providing :except:
  #
  #   RailsMetrics::PayloadParser.add "active_record.sql", :except => :name
  #
  # Or, we could also:
  #
  #   RailsMetrics::PayloadParser.add "active_record.sql", :slice => [:name, :sql]
  #
  # Finally, in some cases manipulating the hash is not enough and you might need
  # to customize it further, as in "action_view.render_template". You can do
  # that by giving a block which will receive the payload as argument:
  #
  #   RailsMetrics::PayloadParser.add "action_view.render_template" do |payload|
  #     payload = payload.dup
  #     payload[:template] = payload[:template].gsub("RAILS_ROOT", Rails.root)
  #     payload
  #   end
  #
  # ATTENTION: if you need to modify the payload or any of its values, be sure to
  # .dup if first, as in the example above.
  #
  # If you want to ignore any payload, you can use the ignore method:
  #
  #   RailsMetrics::PayloadParser.ignore "active_record.sql"
  #
  module PayloadParser
    # Holds the parsers used by RailsMetrics.
    def self.parsers
      @parsers ||= {}
    end

    # Holds the mapped paths used in prunning.
    def self.mapped_paths
      @mapped_paths ||= {}
    end

    # Add a new parser.
    def self.add(*names, &block)
      options = names.extract_options!

      names.each do |name|
        parsers[name.to_s] = if block_given?
          block
        elsif options.present?
          options.to_a.flatten
        else
          true
        end
      end
    end

    # Delete a previous parser
    def self.ignore(*names)
      names.each { |name| parsers[name.to_s] = false }
    end

    # Filter the given payload based on the name given and configured parsers
    def self.filter(name, payload)
      parser = parsers[name]
      case parser
      when Array
        payload.send(*parser)
      when Proc
        parser.call(payload)
      when TrueClass, NilClass
        payload
      when FalseClass
        nil
      end
    end

    # Prune paths based on the mapped paths set.
    def self.prune_path(raw_path)
      mapped_paths.each do |path, replacement|
        raw_path = raw_path.gsub(path, replacement)
      end
      raw_path
    end

    # Make Rails.root appear as APP in pruned paths.
    mapped_paths[Rails.root.to_s] = "RAILS_ROOT"

    # Make Gem paths appear as GEM in pruned paths.
    Gem.path.each do |path|
      mapped_paths[File.join(path, "gems")] = "GEMS_ROOT"
    end if defined?(Gem)

    # ActiveRecord
    add "active_record.sql" do |payload|
      payload = payload.dup
      payload[:sql] = payload[:sql].squeeze(" ")
      payload.delete(:connection_id)
      payload
    end

    # ActionController - process action
    add "action_controller.process_action" do |payload|
      payload = payload.except(:path, :method, :params, :db_runtime, :view_runtime)
      payload[:end_point] = "#{payload.delete(:controller)}##{payload.delete(:action)}"
      payload
    end

    # ActionView
    add "action_view.render_template", "action_view.render_partial",
        "action_view.render_collection" do |payload|
      returning Hash.new do |new_payload|
        payload.each do |key, value|
          case value
          when NilClass
          when String
            new_payload[key] = prune_path(value)
          else
            new_payload[key] = value
          end
        end
      end
    end

    # ActionMailer
    add "action_mailer.deliver", "action_mailer.receive", :except => :mail
  end
end
