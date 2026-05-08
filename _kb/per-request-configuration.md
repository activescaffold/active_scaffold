---
title: "Per Request Configuration"
category: "Advanced"
---

Sometimes you need to configure your scaffold differently for each request. At some level you can do this with the security layer, e.g. authorizing/forbidding the update action. But if you need to fiddle with things not covered by the security layer, you can use a before_action to modify the configuration per-request. The basic setup is like this:

{% highlight ruby -%}
before_action :update_table_config

def update_table_config         
  if condition
    # Change things one way
  end 
end
{%- endhighlight %}

This has better support since threadsafe was added, especially with 4.0 changes. Before threadsafe was supported, the before_action should change back settings to original value in `else` clause. See below for old ActiveScaffold version.

{% highlight ruby -%}
def update_table_config
  if current_user&.per_page
    active_scaffold_config.list.per_page = current_user.per_page
  end
end
{%- endhighlight %}

Changing a column on a request must use `active_scaffold_config.columns.override(:name)` at least the first time.

{% highlight ruby -%}
def update_table_config
  if current_user
    active_scaffold_config.columns.override(:tags).label = current_user.name+"'s Tags"
  end
end
{%- endhighlight %}

After calling `columns.override(:name)`, calling it again or calling `columns[:name]` will return the overrided column, so any way can be used:

{% highlight ruby -%}
before_action :update_table_config

active_scaffold :invoice do |conf|
  conf.columns[:customer].form_ui = :record_select
end

protected

def update_table_config
  if current_user&.customers
    active_scaffold_config.columns.override(:customer).form_ui = :select
    active_scaffold_config.columns.override(:customer).options = {label_method: :user_label}
    active_scaffold_config.columns[:customer].description = 'Pick one of your customers' # same as override(:customer)
  end
end
{%- endhighlight %}

It also supports a block:

{% highlight ruby -%}
def update_table_config
  if current_user&.customers
    active_scaffold_config.columns.override(:customer) do |column|
      column.form_ui = :select
      column.options = {label_method: :user_label}
      column.description = 'Pick one of your customers'
    end
  end
end
{%- endhighlight %}

As the controller config, including column's settings, are frozen, you can't use @merge!@ on column's options, you must assign options to a new hash before, e.g. using @column.options.merge(...)@:

{% highlight ruby -%}
def update_table_column
  if current_user&.date_format
    active_scaffold_config.columns.override(:date) { |col| col.options = col.options.merge(format: current_user.date_format) }
  end
end
{%- endhighlight %}

Changing the columns of an action must use @action.override_columns@ the first time, then call add or exclude, or use assignment:

{% highlight ruby -%}
def update_table_config
  if current_user 
    active_scaffold_config.list.override_columns.exclude :not_required
    active_scaffold_config.list.columns.add :new_column
  end
end
{%- endhighlight %}

Some changes to columns can be handled with helpers too. For example for the label, there are different helpers, so it supports different labels in list, show, form and subform:

In the list, with @column_heading_label@:

{% highlight ruby -%}
def column_heading_label(column)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

In the form, with @form_column_label@:

{% highlight ruby -%}
def form_column_label(column, record, scope)
  if column == :tags && current_user
    record.tags.present? ? "#{current_user.name}'s Tags" : "Add tags for #{current_user.name}"
  else
    super
  end
end
{%- endhighlight %}

In the subform, with horizontal layout (table), no record available, with @subform_label@:

{% highlight ruby -%}
def subform_label(column, hidden)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

In the show, with @show_label@:

{% highlight ruby -%}
def show_label(column)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

To change column's options for the form_ui, a [form override](/doc/form-overrides/) can be used to call the form_ui helper method (@active_scaffold_input_<form_ui>@), with different options based on conditions, passed as named argument @ui_options@. For example, to use different options on create or update form, use @@record.new_record?@ for create when is @true@, and update when is @false@, or condition based on the value of some column:

{% highlight ruby -%}
def parent_user_form_column(record, options)
  column = active_scaffold_config.columns[:user]
  is_admin = current_user.admin? #example dynamic condition
  ui_options = {params: {admin_param: is_admin}}
  active_scaffold_input_record_select(column, options, ui_options: ui_options)
end
{%- endhighlight %}

h2. Before 4.0 version

This was an advanced and experimental technique. It may have unknown quirks.

Sometimes you need to configure your scaffold differently for each request. At some level you can do this with the security layer, e.g. authorizing/forbidding the update action. But if you need to fiddle with things not covered by the security layer, you can use a before_action to modify the configuration per-request. The basic setup is like this:

{% highlight ruby -%}
before_action :update_table_config

def update_table_config         
  if current_user
    # Change things one way
  else
    # Change things back the other way
  end 
end
{%- endhighlight %}

The @else@ clause is not needed when using threadsafe.

Probably the most obvious change is to add or remove columns from the table or to change the column’s (or table’s) labels (giving for example Scott’s Tags or Richard’s Tags instead of just Tags). In order to add or remove columns the way to go is to define all the required columns in the initial configuration and then exclude those that are unwanted in the before_actoin. Labels can be updated by a simple assignment.

Don’t forget to change the configuration back to the way it was if not using threadsafe! In the production environment the configuration is cached in class variables, and changing it for one special user will change it for all users … unless you change it back. Don't use it with threaded servers if not using threadsafe.

{% highlight ruby -%}
def update_table_config
  if current_user 
    active_scaffold_config.list.columns.exclude :not_required
    active_scaffold_config.label = current_user.name
    active_scaffold_config.columns[:tags].label = current_user.name+"'s Tags"
  else
    active_scaffold_config.list.columns.add :not_required
    active_scaffold_config.label = 'Users'
    active_scaffold_config.columns[:tags].label = 'Tags'
  end
end
{%- endhighlight %}

Changes to columns are better handled with helpers. For example for the label, there are different helpers, so it supports different labels in list, show, form and subform:

In the list, with @column_heading_label@:

{% highlight ruby -%}
def column_heading_label(column)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

In the form, with @form_column_label@:

{% highlight ruby -%}
def form_column_label(column, record, scope)
  if column == :tags && current_user
    record.tags.present? ? "#{current_user.name}'s Tags" : "Add tags for #{current_user.name}"
  else
    super
  end
end
{%- endhighlight %}

In the subform, with horizontal layout (table), no record available, with @subform_label@:

{% highlight ruby -%}
def subform_label(column, hidden)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

In the show, with @show_label@:

{% highlight ruby -%}
def show_label(column)
  if column == :tags && current_user
    "#{current_user.name}'s Tags"
  else
    super
  end
end
{%- endhighlight %}

To change column's options for the form_ui, a [form override](/doc/form-overrides/) can be used to call the form_ui helper method (@active_scaffold_input_<form_ui>@), with different options based on conditions, passed as named argument @ui_options@. For example, to use different options on create or update form, use @@record.new_record?@ for create when is @true@, and update when is @false@, or condition based on the value of some column:

{% highlight ruby -%}
def parent_user_form_column(record, options)
  column = active_scaffold_config.columns[:user]
  is_admin = current_user.admin? #example dynamic condition
  ui_options = {params: {admin_param: is_admin}}
  active_scaffold_input_record_select(column, options, ui_options: ui_options)
end
{%- endhighlight %}
