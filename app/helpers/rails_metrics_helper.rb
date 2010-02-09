module RailsMetricsHelper
  # Shows information about the metrics being shown on index page.
  def paginated_index_header
    filters = []
    filters << "name" if @by_name
    filters << "instrumenter id" if @by_instrumenter_id
    filters.map!{ |i| content_tag(:b, i) }

    content = []
    content << "filtered by #{filters.to_sentence}" unless filters.empty?
    content << "ordered by <b>#{@order_by.to_s.humanize.downcase}</b>"

    maximum = [@metrics_count, @offset + @limit].min
    ("Showing #{@offset + 1} - #{maximum} of #{@metrics_count} metrics " << content.to_sentence).html_safe
  end

  # Allows to scope the metrics to the given scope.
  def link_to_scoped_rails_metrics(what, content, value=nil)
    if instance_variable_get(:"@by_#{what}")
      content
    else
      value ||= content
      link_to content, url_for(params.merge(:"by_#{what}" => value, :action => "index")), :title => value
    end
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

  # Link to clear the scope through a cancel item.
  def link_to_clear_scope(what)
    if instance_variable_get(:"@by_#{what}")
      image = image_tag("rails_metrics/cancel.png", :title => "Remove filter", :alt => "Remove filter") 
      url   = url_for(params.merge(:"by_#{what}" => nil))
      link_to(image, url, :title => "Remove filter")
    else
      ""
    end
  end
end