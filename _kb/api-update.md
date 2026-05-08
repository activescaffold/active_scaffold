---
title: "API: Update"
category: "API Reference"
---

## action_group <small><em>global local</em></small>

Set this property so link is included in a group of links.

## add_locking_column <small><em>global local</em></small>

It's enabled by default. When enabled, if the model uses optimistic locking (checked with `locking_enabled?`), then a hidden field for the locking column will be added automatically, no need to add it to `update.columns`.

## columns <small><em>local</em></small>

The set of columns used for the Update action. The columns themselves are not editable here - only their presence in the Update form. Note that the form automatically excludes `:created_on`, `:created_at`, `:updated_on`, and `:updated_at`.

Columns not in this set will not be accepted as input. This is to prevent hackers from sneaking unexpected data into your models.

The Update form supports subgroups. To create a subgroup, call `columns.add_subgroup` and pass a name and a block. The name will be used to label the subgroup in the view, and the block will let you configure the column set like normal.

Example:

{% highlight ruby -%}
config.update.columns = [:username, :password]
config.update.columns.add_subgroup "Name" do |name_group|
  name_group.add :first_name, :middle_name, :last_name
end
{%- endhighlight %}

## field_descriptions <small><em>global local</em></small>

The allowed values are `:show` (default), `:hover` and `:click`. This option allows to change the behaviour of column's description:

- `:show` displays the description next to the field, and next to the header in the horizontal subforms.
- `:hover` displays a `?` next to the field and the header in the horizontal subforms, and the description is displayed when the mouse is over the `?`.
- `:click` displays a `?` next to the field and the header in the horizontal subforms, and the description is displayed by clicking in the `?`, then the description can be closed clicking on the `X`.

## floating_footer <small><em>global local</em></small>

A flag to enable floating footer, so buttons of form footer are floating when the form is too big to fit in the window, and they are always accessible without scrolling down.

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for the update action you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.update.formats << :pdf
# or
config.update.formats = [:pdf]
{%- endhighlight %}

## hide_nested_column <small><em>local</em></small>

ActiveScaffold doesn't display nested column in forms. Enable this property so when you edit a record from a nested scaffold parent column will be displayed.

## label <small><em>local</em></small>

The heading used for the Create action interface. Normally this heading is based on the core's label.

## link <small><em>global local</em></small>

The action link used to tie the "update" action to the List table.  Most likely, you'll use this to change the label for your link.

{% highlight ruby -%}
config.update.link.label = "Edit User"
{%- endhighlight %}

See [API: Action Link](/doc/api-action-link/) for additional parameters for this link.

## multipart <small><em>local</em></small>

A flag for whether the form should be multipart or not. This is typically used to support file uploads.

## nested_links <small><em>global local</em></small>

A flag for whether nested links should be shown at page top or not. Only they will be shown when it's update form is loaded in page, not in list over AJAX.

## persistent <small><em>global local 2.4+</em></small>

A flag for whether the update form should be persistent or not. If persistent, then after a successful update it will stay open. Default is false.

Since 3.2.15 you can set persistent to :optional, and you will get "Update" and "Apply" buttons.

## refresh_list <small><em>global local</em></small>

Enable this property to refresh list after successful update when form is sent with AJAX.

## show_unauthorized_columns <small><em>global local</em></small>

ActiveScaffold doesn't display unauthorized columns in forms. Enabling this property they will be displayed, showing the current value without a field.

# Controller Methods

## before_update_save [controller method]

If you want to add or tweak some data before the record gets saved, define this method on your controller. But first, be sure you don't want to define a [callback](http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html) on your ActiveRecord model instead! This controller method is most useful for adding session-specific data to your model, like the current user.

Example:

{% highlight ruby -%}
class TaskController < ApplicationController
  active_scaffold :tasks

  protected

  def before_update_save(record)
    record.updated_by = current_user
  end
end
{%- endhighlight %}

## after_update_save [controller method]

Similar to the above, but after your record is updated/saved.

## on_stale_object_error [controller method]

Called when StaleObjectError is raised. The exception is rescued, and a error message is added to the record, the message uses the translation key `version_inconsistency` under the `active_scaffold` scope.