layout 'normal.html'

@breadcrumb_links = {}

def description
  if @description.nil?
    @page_title
  else
    @description
  end
end

def add_breadcrumbs(breadcrumbs)
  @breadcrumb_links.merge!(breadcrumbs)
end

def breadcrumbs(breadcrumbs)
  html = []

  #last = breadcrumbs.pop
  last = @page_title
  breadcrumbs.each do |breadcrumb|
    url = @breadcrumb_links[breadcrumb]
    html.push("<a href=\"#{url}\">#{breadcrumb}</a>")
  end
  html.push("<b>#{last}</b>")

  return html.join(" &gt; ")
end

add_breadcrumbs(
  "MAME OS X Manual" => link_rel('/index.html'),
  "Contents"  => link_rel('/contents.html')
)
@breadcrumbs = ["MAME OS X Manual", "Contents"]
