module RailsMetricsHelper
  def link_to_scoped_rails_metrics(what, content, value=nil)
    if instance_variable_get(:"@by_#{what}")
      content
    else
      value ||= content
      link_to content, url_for(params.merge(:"by_#{what}" => value)), :title => value
    end
  end

  def payload_inspect(hash)
    content = []
    hash.each do |key, value|
      value = value.inspect unless value.is_a?(String)
      content << (content_tag(:b, key.to_s.humanize).safe_concat("<br />") << value)
    end
    content.map!{ |c| content_tag(:p, c) }
    content.join("\n").html_safe
  end

  def link_to_clear_scope(what)
    if instance_variable_get(:"@by_#{what}")
      image = image_tag("rails_metrics/cancel.png", :title => "Remove filter", :alt => "Remove filter") 
      url   = url_for(params.merge(:"by_#{what}" => nil))
      link_to(image, url)
    else
      ""
    end
  end
end