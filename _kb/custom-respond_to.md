---
title: "Custom respond_to"
category: "Advanced"
---

By default ActiveScaffold responds to the HTML, JavaScript, JSON, and XML MIME types. Use [`default_formats`](/doc/api-core/#default_formats) to change these defaults globally or per controller. The `config.formats` and action-specific `formats` settings add formats to the configured defaults.

If you want to override one of these responses, override the `<action>_respond_to_<format>` method in the controller:

{% highlight ruby -%}
  def show_respond_to_html
    render :action => :show, :layout => 'main'
  end

  def list_respond_to_xml
       render :xml => @records.to_xml(:except => [:full_definition, :cradle_item_type_id], :include => [:cradle_item_type]) 
  end
{%- endhighlight %}

If you need to add a custom mime type you can do it in one of two ways.

{% highlight ruby -%}
  # to add a mime type to all actions
  active_scaffold do |config|
    config.formats << :pdf
  end

  # to add it to only one action
  active_scaffold do |config|
    config.show.formats << :pdf
  end
{%- endhighlight %}

So now your controller or action will respond to that format.  Now you need to hook into the response type for that action.

{% highlight ruby -%}
def show_respond_to_pdf
  #render whatever you want here
end
{%- endhighlight %}

List action will load records in @`records` variable, other actions will load the record in @`record` variable