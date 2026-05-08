---
title: "API: mark"
category: "API Reference"
---

Enable mark records in list. It will add a checkbox at each row to select the record, and a checkbox to select all records. Selected records will be stored in the session and you can get currently selected records with the controller method marked_records. You can get the marked records from the model with marked_records class method too, and check if a record is marked with as_marked method.

Example (don’t forget to add appropriate changes to routes.rb!):

{% highlight ruby -%}
class ModelsController < ApplicationController
  active_scaffold :model do |conf|
    conf.actions.add :mark
    conf.action_links.add :delete_selected, :type => :collection, :method => :delete
  end

  def delete_selected
    each_marked_record do |record|
      record.as_marked = false if record.destroy
    end
    head :ok # FIXME: You should delete it and write some js view or something else
  end
end
{%- endhighlight %}

## mark_all_mode <small>global local</small>

It allows to change which records will be marked on clicking mark all checkbox. Set to `:page` to mark all records in current page. By default is `:search` which will mark all records in the list, using current search conditions.