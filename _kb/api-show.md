---
title: "Api: show"
category: "API Reference"
---

## actions <small><em>global local</em></small>

Set this property so link is included in a group of links.

## columns <small><em>local</em></small>
The set of columns used in the Show view. The columns themselves are not editable here – only their presence in the Show view.

## formats
Active scaffold supports html, js, json, yaml, and xml formats by default. If you need to add another mime type for the show action you can do it here. The format is then added to the default formats.

Examples:
{% highlight ruby -%}
config.show.formats << :pdf
# or
config.show.formats = [:pdf]
{%- endhighlight %}

## label <small><em>local</small></em>
The heading used for the Show view. Normally this heading is based on the core’s label.

## link <small><em>global local</small></em>
The action link used to tie the Show view to the List table. See API: Action Link for the options on this setting.

Examples:
{% highlight ruby -%}
# set link label 
config.show.link.label = "show user"
    
# set link title  
config.show.link.html_options = { :title => "show user details..." }

# render an image as link label  
config.show.link.label = helpers.image_tag( "show_user_24x32.png", 
                                            :title => "show user deatils", 
                                            :alt => "show user", 
                                            :size => "24x32").html_safe
{%- endhighlight %}
## Overrides
Need to modify the show command, for example to allow a file download

{% highlight ruby -%}
class FramesController < ApplicationController

  active_scaffold :frames do |config|
     config.show.columns << :attachment_type
  end

  def do_show
   	@record = find_if_allowed(params[:id], :read)
  end

  def show_respond_to_html
    if params[:download] 
       #storing the attachment in the database in a column bdata, and binary data is base64 encoded (legacy schema).  
       #send_file would be used if the file existed in the OS file storage system. 
        send_data(Base64.decode64(@record.bdata),
 			:filename => @record.filename,
 			:disposition => "attachment",
 			:type =>  @record.mime_type)
    else
       render :action => 'show'
    end
  end
end

#using the "attachment_type" column to hold the download link
module FramesHelper
   def frame_attachment_type_column(record)
      record.attachment_type ? link_to(record.filename, frame_path(record, :download => true)) : nil
    end
end
{%- endhighlight %}
