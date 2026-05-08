---
title: "API: FieldSearch"
category: "API Reference"
---

The FieldSearch action is an advanced search. It provides a UI to allow specification of a value and operator for each searchable field.  Text fields can be searched using operators such as "Begins With", "Ends With", "Contains", "=", ">=", etc.

## action_group <small><em>global local</em></small>

Set this property so link is included in a group of links.

## columns <small><em>local</em></small>

The set of searchable columns. This list defaults to the textual database fields.
{% highlight ruby -%}
config.field_search.columns = :user_type, :widget_id, :name, :owner, :status
{%- endhighlight %}

For virtual columns you must also set the "search_sql" option or the field will not appear on the search form.

{% highlight ruby -%}
config.columns[:admin_roles].search_sql = 'users.role_id'
{%- endhighlight %}
The value of "search_sql" will also be available in the [Search Overrides](/doc/search-overrides/) condition_for_x method in case you need to customize the search SQL.

## default_params <small><em>local</em></small>

Set the default params for some fields.

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for field search, you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.field_search.formats << :pdf
# or
config.field_search.formats = [:pdf]
{%- endhighlight %}

## full_text_search <small><em>global local until v2.2</em></small>

A flag for whether the search should do full-text searching in the database (LIKE %?%) or assume that search tokens will match the beginning (LIKE ?%). Default is :true.

> Since v2.3 is replaced with text_search

## group_options <small><em>local</em></small>

An array of column names so user can pick one column to group by it and get aggregated list. The values can be symbols of column names, which will display the column's translated name, or an array of label and column name. Instead of column name, a `<column>#<function>` string can be used, to group by column using SQL function. See [Grouped Searches](/doc/grouped-searches/) for a further explanation.

## grouped_columns <small><em>local</em></small>

An array of column names to replace `config.list.columns` when using a grouped search. If not defined, it will default to include all columns from `config.list.columns` which have calculation defined. The group column is always added at the beginning.

## human_conditions <small><em>global local</em></small>

Enable it to display a message with humanized search conditions instead of default filtered message.

## link <small><em>global local</em></small>

The action link used to tie the Search box to the List table. See [API: Action Link](/doc/api-action-link/) for the options on this setting.

## optional_columns <small><em>local</em></small>

Put some rarely-used columns in a hidden group.

## reset_form <small><em>global local v3.7.3+</em></small>

When enabled, reset link will clear input fields in the search form, instead of refreshing the list without search and closing the form.

## text_search <small><em>global local v2.3+</em></small>

A flag for how the search should do full-text searching in the database:

- :full (LIKE %%?%%)
- :start (LIKE ?%)
- :end (LIKE %?)
- false (LIKE ?)

Default is `:full`.

When a drop down (select) is used, the "false" option will use LIKE with no wild cards, which is fast!
{% highlight ruby -%}
config.field_search.text_search = false
{%- endhighlight %}

## update_columns <small><em>global local v3.7.12+</em></small>

A flag to enable refreshing columns when a column is changed with update_columns defined, as create and update forms do.

{% highlight ruby -%}
config.field_search.update_columns = true
{%- endhighlight %}

# [API: Column](/doc/api-column/) related methods

## search_ui <small><em>local</em></small>

To customize the search form columns, use search_ui (similar to form_ui). Note that we can't use a :checkbox search_ui because it's not possible to determine whether or not to search for that field (:checkbox will silently render a :boolean search_ui, which is displayed as a select)

Examples:

Field Search Example (with dropdown for user type)
{% highlight ruby -%}
class UsersController < ActionController::Base
  active_scaffold :users do |config|
     config.actions = [:nested, :list, :show, :field_search]
     config.columns[:user_type].search_ui = :select
  end
end

module UsersHelper
  # display the "user_type" field as a dropdown with options
  def user_type_search_column(record, input_name)
    select :search, :user_type, options_for_select(User.user_types), {:include_blank => as_(:_select_)}, input_name
  end
end
{%- endhighlight %}
