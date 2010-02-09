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

  # Allows to scope the metrics to the given scope.
  def link_to_scoped_rails_metrics(what, content, value=nil)
    return content if instance_variable_get(:"@by_#{what}")
    value ||= content
    link_to content, url_for_scope(what, value), :title => value
  end

  # Link to clear the scope through a cancel item.
  def link_to_clear_scope(what)
    return unless instance_variable_get(:"@by_#{what}")
    image = image_tag("rails_metrics/cancel.png", :title => "Remove filter", :alt => "Remove filter") 
    link_to(image, url_for_scope(what), :title => "Remove filter")
  end

  protected

  def url_for_scope(what, value=nil)
    url_for(params.except(:limit, :offset, :action).merge(:"by_#{what}" => value))
  end
end