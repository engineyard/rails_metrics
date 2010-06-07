module RailsMetricsHelper
  module Pagination
    # Returns information about pagination
    def pagination_info
      maximum = [@metrics_count, @offset + @limit].min
      "#{@offset + 1} - #{maximum} of #{@metrics_count}"
    end

    # Shows per page links
    def show_per_page(values)
      values.map do |i|
        link_to_unless(@limit == i, i.to_s, url_for(params.merge(:limit => i)))
      end.join(" | ").html_safe
    end

    # Shows previous link for pagination
    def previous_link
      link = url_for(params.merge(:offset => [0, @offset - @limit].max))
      link_to_if(@offset > 0, "Previous", link)
    end

    # Show next link for pagination
    def next_link
      link = url_for(params.merge(:offset => @offset + @limit))
      link_to_if(@offset + @limit < @metrics_count, "Next", link)
    end

    # Add pagination to footlinks
    def paginate!
      content_for :rails_metrics_footlinks do
        content_tag(:p, [previous_link, pagination_info, next_link].join(" | "),nil,false) <<
        content_tag(:p, "Show per page: #{show_per_page([10, 25, 50, 100])}",nil,false)
      end
    end
  end

  module PayloadInspect
    # Inspect payload to show more human readable information.
    def payload_inspect(hash)
      hash = hash.sort {|a,b| a[0].to_s <=> b[0].to_s }
      content = []

      hash.each do |key, value|
        content << (content_tag(:b, key.to_s.humanize).safe_concat("<br />") << pretty_inspect(value))
      end

      content.map!{ |c| content_tag(:p, c) }
      content.join("\n").html_safe
    end

    # Inspect a value using a more readable format.
    def pretty_inspect(object)
      case object
        when String
          object
        when Array
          "[#{object.map(&:inspect).join(", ")}]"
        when Hash
          hash = object.map { |k,v| "  #{k.inspect} => #{pretty_inspect(v)}" }.join(",\n")
          if object.size == 1
            "{ #{hash[2..-1]} }"
          else
            "{\n#{hash}\n}"
          end
        else
          object.inspect
      end
    end
  end

  module Scoping
    # Returns information about scope
    def scopes_info
      filters = []
      filters << "name" if @by_name
      filters.map!{ |i| content_tag(:b, i) }

      content = []
      content << "filtered by #{filters.to_sentence}" unless filters.empty?
      content << "ordered by <b>#{@order_by.to_s.humanize.downcase}</b>"
      content.to_sentence.html_safe
    end

    # Link to set a by_scope using the given content. If no value is given,
    # the content is used as link value as well.
    def link_to_set_by_scope(metric, what)
      value = metric.send(what)
      return value if instance_variable_get(:"@by_#{what}")
      link_to value, url_for_scope(:"by_#{what}" => value, :action => "all"), :title => value
    end

    # Link to clear a by_scope using a cancel image.
    def link_to_clear_by_scope(what)
      return unless instance_variable_get(:"@by_#{what}")
      link_to_set_scope_with_image("rails_metrics/cancel.png",
        "Remove #{what.to_s.humanize.inspect} filter", :"by_#{what}" => nil)
    end

    # Link to order by scopes by using two arrows, one up and other down
    def link_to_order_by_scopes(up, down)
      link_to_set_scope_with_image("rails_metrics/arrow_up.png", "Order by #{up}", :order_by => up) <<
        link_to_set_scope_with_image("rails_metrics/arrow_down.png", "Order by #{down}", :order_by => down)
    end

  protected

    def url_for_scope(hash) #:nodoc:
      url_for(params.except(:limit, :offset, :id).merge!(hash))
    end

    def link_to_set_scope_with_image(src, title, scope) #:nodoc:
      image = image_tag(src, :title => title, :alt => title)
      link  = url_for_scope(scope)
      link_to image, link, :title => title
    end
  end

  module Links
    # Links to image inside rails_metrics if the given path it's not the current page using the given title.
    def link_to_image_unless_current(icon, path, title)
      return if current_page?(path)
      image = image_tag("rails_metrics/#{icon}.png", :title => title, :alt => title)
      link_to image, path, :title => title
    end

    # Add action icons to the current page.
    def add_action_links!(metric)
      concat link_to_image_unless_current(:chart_pie, chart_rails_metric_path(metric.request_id), "Chart")
      concat link_to_image_unless_current(:page_white_go, rails_metric_path(metric), "Show")
      form_tag(rails_metric_path(metric), :method => :delete) do
        image_submit_tag "rails_metrics/page_white_delete.png", :onclick => "return confirm('Are you sure?')", :alt => "Delete", :title => "Delete"
      end
    end

    def nagivation_links
      @navigation_links ||= begin
        links = []
        links << link_to("All metrics", all_rails_metrics_path)
        links << link_to("Requests", rails_metrics_path)
        links << link_to("Back", :back)
        links.join(" | ").html_safe
      end
    end
  end

  include Pagination
  include PayloadInspect
  include Scoping
  include Links

  # Returns pagination and scopes information
  def pagination_and_scopes_info(countable)
    countable = countable.to_s.pluralize unless @metrics_count == 1
    "Showing #{pagination_info} #{countable} ".html_safe << scopes_info
  end

  # Create a table row using rails_metrics_#{id} as row id and odd and even as classes.
  def rails_metrics_table_row_for(metric, &block)
    content_tag(:tr, :id => "rails_metric_#{metric.id}", :class => cycle("odd", "even"), &block)
  end
end