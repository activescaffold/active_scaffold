---
title: "Search Overrides"
category: "Customization"
---

If you want to customize the search form interface for a column (in field search), you can define a specially named method in your helper file. The format is `#{class_name}_#{column_name}_search_column` or `#{column_name}_search_column`. So, for example, to customize the `:username` column displayed on your search view of `UsersController`, you would add a `user_username_search_column` method to your `UsersHelper` file. If you want the post to be handled by ActiveScaffold, you need to use the params[:search] namespace. With the helper override this is taken care of if you use the second argument: the options hash. See the example below for more details. Later name will override columns from all models (unless you use `clear_helpers` method in `ApplicationController`) or if you put it in `ApplicationHelper`.

> In v2.3 and previous versions format was only `#{column_name}_search_column`, so method was named `username_search_column`.

Example:

{% highlight ruby -%}
module UsersHelper
  # display the "status" field as a dropdown with open and closed options
  def user_status_search_column(record, options)
    select :record, :status, options_for_select(['open', 'closed']), {:include_blank => as_('- select -')}, options
  end
end
{%- endhighlight %}

> Until v2.3 the second argument was only the input name instead of a full options hash, so you would use `check_box :record, :is_admin, :name => input_name`. See example below:

{% highlight ruby -%}
module UsersHelper
  # display the "status" field as a dropdown with open and closed options, in v2.3 there is no class name prefix
  def status_search_column(record, input_name)
    select :record, :status, options_for_select(['open', 'closed']), {:include_blank => as_('- select -')}, :name => input_name
  end
end
{%- endhighlight %}

If the association is defined in a STI model, prefixing with the base class is supported too, so subclasses can use a helper override prefixed with own class name, which is specific for the subclass, or share a helper override with the base class name prefix. For example:

{% highlight ruby -%}
class Admin < User
end

class Member < User
end
{%- endhighlight %}

Admin will look for `admin_status_search_column` and `user_status_search_column`, and Member will look for `member_status_search_column` and `user_status_search_column`, so `user_status_search_column` can be defined to use the same field in both models. This is more useful when `clear_helpers` is not called in `ApplicationController`, or when the method is defined in `ApplicationHelper` or any other shared Helper module.

You can customize conditions for a specific column adding a class method to the controller named `condition_for_#{column_name}_column`. That method should return a conditions array.

Example:

{% highlight ruby -%}
class UsersController < ApplicationController
  def self.condition_for_status_column(column, value, like_pattern)
    case value
      when 'open'
        ["#{column.search_sql} IS NOT NULL"]
      when 'closed'
        ["#{column.search_sql} IS NULL"]
    end
  end

  active_scaffold do |config|
    ...
  end
end
{%- endhighlight %}

Also you can customize conditions for a search_ui or type column, adding a class method to the controller named `condition_for_#{search_ui}_type`. This method should return a conditions array, with query string to interpolate :search_sql, and required values to build the sql. `%{search_sql}` will be replaced with each item in column.search_sql and resulting chunks will be OR'ed so an ActiveScaffold column can search in multiple DB columns.

{% highlight ruby -%}
class ApplicationController < ActionController::Base
  def self.condition_for_time_range_type(column, value, like_pattern)
    case value
      when 'morning'
        ['%{search_sql} BETWEEN ? AND ?', 6, 12]
      when 'afternoon'
        ['%{search_sql} BETWEEN ? AND ?', 13, 19]
      when 'night'
        ['%{search_sql} BETWEEN ? AND ? OR %{search_sql} BETWEEN ? AND ?', 0, 5, 20, 23]
    end
  end
end
{%- endhighlight %}

## Searches on Combinations of attributes

Here is an example with a few "virtual" searches setup.  In other words, search on a specific combination of conditions.
For your virtual search to "show up" takes a bit, best shown by example.  

> Note the seemingly un-needed config.columns[:src_or_tgt_pduid].search_sql = '' is needed for the condition/virtual-column to show up on the search form.

{% highlight ruby -%}
class CachedLinksController < ApplicationController
  active_scaffold do |config|
    config.actions = [:list, :show, :field_search, :nested]
    config.list.columns = [:src_cradle_id, :src_pduid, :src_version, :tgt_cradle_id, :tgt_pduid, :tgt_version, :lnk_type,
                           :lnk_class, :source_item, :target_item]
    config.list.per_page = 20
    config.field_search.columns = [:src_cradle_id, :src_version, :tgt_cradle_id, :tgt_version,
                                   :lnk_type, :lnk_class, :mod_date, :src_note_type, :tgt_note_type,
                                   :src_or_tgt_pduid, :dig_it_latest, :src_pduid, :tgt_pduid]
    config.columns[:src_cradle_id].label = "SRC Cradle ID"
    config.columns[:tgt_cradle_id].label = "TGT Cradle ID"
    config.field_search.human_conditions = true

    config.columns.add :src_or_tgt_pduid
    config.columns[:src_or_tgt_pduid].search_sql = ''
    config.show.columns.exclude :src_or_tgt_pduid

    config.columns.add :dig_it_latest
    config.columns[:dig_it_latest].search_ui = :select
    config.columns[:dig_it_latest].search_sql = ''
    config.show.columns.exclude :dig_it_latest

  end

  def self.condition_for_src_or_tgt_pduid_column(column, value,like_pattern)
    ["src_pduid LIKE ? OR tgt_Pduid LIKE ?", value,value] if value != ''
  end

  def self.condition_for_dig_it_latest_column(column, value, like_pattern)
    if value == '0'
      [" (src_latest_budo ='F' OR src_soft_deleted = 'T' OR tgt_soft_deleted ='T' OR tgt_latest_budo ='F') "]
    elsif value == '1'
      [" (src_latest_budo ='T' AND src_soft_deleted = 'F' AND tgt_soft_deleted ='F' AND tgt_latest_budo ='T') "]
    end
  end

end
{%- endhighlight %}

{% highlight ruby -%}
module CachedLinksHelper

  ...

  def src_or_tgt_pduid_human_condition_column(value, options)
    "#{CachedLink.human_attribute_name(:src_or_tgt_pduid)} LIKE #{value}"
  end

  def dig_it_latest_search_column(record, input_name)
    select :record, :dig_it_latest, options_for_select([["False",0],["True",1]]), {:include_blank => as_('- select -')}, input_name
  end

  def dig_it_latest_human_condition_column(value, options)
    if value == '0'
     return "#{CachedLink.human_attribute_name(:dig_it_latest)}: 
       (src_latest_budo ='F' OR src_soft_deleted = 'T' OR tgt_soft_deleted ='T' OR tgt_latest_budo ='F') " 
    elsif value == '1'
     return  "#{CachedLink.human_attribute_name(:dig_it_latest)}: 
      (src_latest_budo ='T' AND src_soft_deleted = 'F' AND tgt_soft_deleted ='F' AND tgt_latest_budo ='T') "
    end
  end

end
{%- endhighlight %}

{% highlight ruby -%}
class CachedLink < ActiveRecord::Base

  # Define an attribute to "set" from the select UI on the search page
  attribute :dig_it_latest

end
{%- endhighlight %}
