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
    @@parsers = {}

    def self.add(*names, &block)
      options = names.extract_options!

      names.each do |name|
        @@parsers[name.to_s] = if block_given?
          block
        elsif options.present?
          options.to_a.flatten
        else
          :all
        end
      end
    end

    def self.delete(*names)
      names.each { |name| @@parsers.delete(name.to_s) }
    end

    def self.filter(name, payload)
      parser = @@parsers[name]
      case parser
      when Array
        payload.send(*parser)
      when Proc
        parser.call(payload)
      when :all
        payload
      end
    end

    add "active_record.sql", :slice => [:name, :sql]

    add "action_controller.write_fragment", "action_controller.read_fragment",
        "action_controller.exist_fragment?", "action_controller.expire_fragment",
        "action_controller.expire_page", "action_controller.cache_page"

    add "action_view.render_template", "action_view.render_layout",
        "action_view.render_partial", "action_view.render_collection" do |payload|
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

    # TODO Check what is better to output here
    add "action_controller.process_action" do |payload|
      controller = payload[:controller]

      {
        :controller => controller.controller_name,
        :action     => payload[:action],
        :method     => controller.request.method,
        :formats    => controller.request.formats.map(&:to_s)
      }
    end

    add "action_mailer.deliver" do |payload|
      mail = payload[:mail]

      {
        :from       => mail.from,
        :recipients => mail.recipients,
        :subject    => mail.subject,
        :mailer     => mail.mailer_name,
        :template   => mail.template
      }
    end

    # TODO Render with exception
    # add "action_dispatch.show_exception"

    # TODO redirect_to
    # add "action_controller.redirect_to"

    # TODO send_data
    # add "action_controller.send_data"
  end
end