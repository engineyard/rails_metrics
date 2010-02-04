module RailsMetrics
  # Usually the payload for a given notification contains a lot of information,
  # as backtrace, controllers, response bodies and so on, and we don't need to
  # store all this data in the database.
  #
  # So, by default, RailsMetrics does not store any payload in the database, unless
  # you configure it. To do that, you simply need to call +add+:
  #
  #   RailsMetrics::PayloadParser.add "active_record.sql"
  #
  # "activerecord.sql" has as paylaod the :name (like "Product Load") and the :sql
  # to be performed. And now both of them will be stored in the database. You can
  # also select or remove any information from the hash through :slice and :except
  # options:
  #
  #   RailsMetrics::PayloadParser.add "active_record.sql", :slice => :sql
  #
  # Or:
  #
  #   RailsMetrics::PayloadParser.add "active_record.sql", :except => :name
  #
  # Finally, in some cases manipulating the hash is not enough and you might need
  # to customize it further, as in "action_controller.process_action". In such
  # cases, you can pass a block which will receive the payload as argument:
  #
  #   RailsMetrics::PayloadParser.add "action_controler.process_action" do |payload|
  #     { :method => payload[:controller].request.method }
  #   end
  #
  # ATTENTION: if you need to modify the payload or any of its values, be sure to
  # .dup if first.
  #
  # RailsMetrics all come with default parsers (defined below), but if you want to gather
  # some info for other libraries (for example, paperclip) you need to define the parser
  # on your own. You can remove any parser whenever you want:
  #
  #   RailsMetrics::PayloadParser.delete "active_record.sql"
  #
  module PayloadParser
    @parsers = {}

    def self.add(*names, &block)
      options = names.extract_options!

      names.each do |name|
        @parsers[name.to_s] = if block_given?
          block
        elsif options.present?
          options.to_a.flatten
        else
          :all
        end
      end
    end

    def self.delete(*names)
      names.each { |name| @parsers.delete(name.to_s) }
    end

    def self.filter(name, payload)
      parser = @parsers[name]
      case parser
      when Array
        payload.send(*parser)
      when Proc
        parser.call(payload)
      when :all
        payload
      end
    end

    # ActiveRecord
    add "active_record.sql"

    # ActionController - cache
    add "action_controller.write_fragment", "action_controller.read_fragment",
        "action_controller.exist_fragment?", "action_controller.expire_fragment",
        "action_controller.expire_page", "action_controller.write_page"

    # ActionController - process action
    add "action_controller.process_action", :except => :params

    add "action_controller.redirect_to", "action_controller.send_data",
        "action_controller.send_file"

    # ActionView
    add "action_view.render_template", "action_view.render_partial",
        "action_view.render_collection" do |payload|
      returning Hash.new do |new_payload|
        payload.each do |key, value|
          case value
          when String
            new_payload[key] = value.gsub(Rails.root.to_s, "RAILS_ROOT")
          when NilClass
            # Ignore it
          else
            new_payload[key] = value
          end
        end
      end
    end

    # ActionMailer
    add "action_mailer.deliver", "action_mailer.receive", :except => :mail

    # ActiveResource
    add "active_resource.request"
  end
end
