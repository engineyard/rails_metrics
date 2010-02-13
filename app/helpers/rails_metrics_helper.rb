module RailsMetricsHelper
  # Returns pagination and scopes information
  def pagination_and_scopes_info
    "Showing #{pagination_info} metrics ".html_safe << scopes_info
  end

  # Returns information about pagination
  def pagination_info
    maximum = [@metrics_count, @offset + @limit].min
    "#{@offset + 1} - #{maximum} of #{@metrics_count}"
  end

  # Returns information about scope
  def scopes_info
    filters = []
    filters << "name" if @by_name
    filters << "instrumenter" if @by_instrumenter_id
    filters.map!{ |i| content_tag(:b, i) }

    content = []
    content << "filtered by #{filters.to_sentence}" unless filters.empty?
    content << "ordered by <b>#{@order_by.to_s.humanize.downcase}</b>"
    content.to_sentence.html_safe
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

  # Inspect payload to show more human readable information.
  def payload_inspect(hash)
    content = []
    hash.each do |key, value|
      value = value.inspect unless value.is_a?(String)
      content << (content_tag(:b, key.to_s.humanize).safe_concat("<br />") << value)
    end
    content.map!{ |c| content_tag(:p, c) }
    content.join("\n").html_safe
  end

  # Link to set a by_scope using the given content. If no value is given,
  # the content is used as link value as well.
  def link_to_set_by_scope(metric, what)
    value = metric.send(what)
    return value if instance_variable_get(:"@by_#{what}")
    link_to value, url_for_scope(:"by_#{what}" => value), :title => value
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

  def url_for_scope(hash)
    url_for(params.except(:limit, :offset, :action).merge!(hash))
  end

  def link_to_set_scope_with_image(src, title, scope)
    image = image_tag(src, :title => title, :alt => title)
    link  = url_for_scope(scope)
    link_to image, link, :title => title
  end
end