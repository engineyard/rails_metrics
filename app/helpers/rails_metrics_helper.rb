module RailsMetricsHelper
  def link_to_scoped_rails_metrics(what, content, value=nil)
    value ||= content
    link_to content, url_for(params.merge(:"by_#{what}" => value)), :title => value
  end
end