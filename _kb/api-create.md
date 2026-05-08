---
title: "API: Create"
category: "API Reference"
---

## action_after_create <small><em>global local v2.3+</em></small>

An action which should be displayed after create a record. If nil, then after a successful create update form will be closed or redirected to index. Default is nil.

## action_group <small><em>global local</em></small>

Set this property so link is included in a group of links.

## columns <small><em>local</em></small>

The set of columns used for the Create action. The columns themselves are not editable here - only their presence in the Create form. Note that the form automatically excludes `:created_on`, `:created_at`, `:updated_on`, and `:updated_at`.

Columns not in this set will not be accepted as input. This is to prevent hackers from sneaking unexpected data into your models.

The Create form supports column grouping. To create a subgroup, call `columns.add_subgroup` and pass a name and a block. The name will be used to label the subgroup in the view, and the block will let you configure the column set like normal.

Example:

{% highlight ruby -%}
config.create.columns = [:username, :password]
config.create.columns.add_subgroup "Name" do |name_group|
  name_group.add :first_name, :middle_name, :last_name
end
{%- endhighlight %}

## edit_after_create <small><em>global local until v2.2</em></small>

A flag for whether the update form should be shown after create a record or not. If true, then after a successful create update form will be open. Default is false.

> Since v2.3 is replaced with action_after_create

## field_descriptions <small><em>global local</em></small>

The allowed values are `:show` (default), `:hover` and `:click`. This option allows to change the behaviour of column's description:

- `:show` displays the description next to the field, and next to the header in the horizontal subforms.
- `:hover` displays a `?` next to the field and the header in the horizontal subforms, and the description is displayed when the mouse is over the `?`.
- `:click` displays a `?` next to the field and the header in the horizontal subforms, and the description is displayed by clicking in the `?`, then the description can be closed clicking on the `X`.

## floating_footer <small><em>global local</em></small>

A flag to enable floating footer, so buttons of form footer are floating when the form is too big to fit in the window, and they are always accessible without scrolling down.

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for the create action you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
# Add a format
config.create.formats << :pdf
{%- endhighlight %}

## label <small><em>local</em></small>

The heading used for the Create action interface. Normally this heading is based on the core's label.

## link <small><em>global local</em></small>

The action link used to tie the Create action to the List table.  Most likely, you'll use this to change the label for your link.

{% highlight ruby -%}
config.create.link.label = "Add a new user"
{%- endhighlight %}

See [API: Action Link](/doc/api-action-link/) for additional parameters for this link.

## multipart <small><em>local</em></small>

A flag for whether the form should be multipart or not. This is typically used to support file uploads.

## persistent <small><em>global local</em></small>

A flag for whether the create form should be persistent or not. If persistent, then after a successful create it will stay open. Default is false.

## refresh_list <small><em>global local</em></small>

Enable this property to refresh list after successful creation when form is sent with AJAX.

## show_unauthorized_columns <small><em>global local</em></small>

ActiveScaffold doesn't display unauthorized columns in forms. Enabling this property they will be displayed.

## before_create_save [controller method]

If you want to add or tweak some data before the record gets saved, define this method on your controller. But first, be sure you don't want to define a [callback](http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html) on your ActiveRecord model instead! This controller method is most useful for adding session-specific data to your model, like the current user.

Example:

{% highlight ruby -%}
class TaskController < ApplicationController
  active_scaffold :tasks

  protected

  def before_create_save(record)
    record.created_by = current_user
  end
end
{%- endhighlight %}


## after_create_save [controller method]

Similar to the above, but after your record is created/saved.
