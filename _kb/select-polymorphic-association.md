---
title: "Select Polymorphic Association"
category: "Advanced"
---

To select records in a polymorphic association, you have to choose first which model you want to select from, so foreign_type column must be added to the form, with :select form_ui, the possible class names as options and update_columns to update the polymorphic association.

{% highlight ruby -%}
class Comment < ActiveRecord::Base  
  belongs_to :commentable, :polymorphic => true  
end  

class Article < ActiveRecord::Base  
  has_many :comments, :as => :commentable
end

class Photo < ActiveRecord::Base  
  has_many :comments, :as => :commentable
end

class CommentsController < ApplicationController
  active_scaffold do |conf|
    conf.columns << :comment_type
    conf.columns[:comment_type].form_ui = :select
    conf.columns[:comment_type].options = {:options => ['Article', 'Photo'], :include_blank => true}
    conf.columns[:comment_type].update_columns = [:comment]
  end
end
{%- endhighlight %}

In some cases, _send_form_on_update_column_ needs to be enabled, so options for select can be restricted by other column. In that case, when no value is selected on polymorphic association, type column will be nullified, and after_render_field needs to be added to set type column:

{% highlight ruby -%}
class CommentsController < ApplicationController
  active_scaffold do |conf|
    [...]
    conf.columns[:comment_type].send_form_on_update_column = true
  end

  protected
  def after_render_field(record, column)
    record.commentable_type = params[:record][:commentable_type] if record.commentable.nil?
  end
end
{%- endhighlight %}
