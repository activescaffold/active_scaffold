---
title: "Duplicating rows in subforms"
category: "Plugins"
---

ActiveScaffoldDuplicate 2.0 can add a **Duplicate** link next to the remove link on rows in a collection subform. This is useful when several associated records share most of their values: duplicate the closest row, change the fields that differ, and save the parent form as usual.

This feature requires ActiveScaffold 4.2 or newer.

## Install the plugin

Add the plugin to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_duplicate', '~> 2.0'
{%- endhighlight %}

Then install it:

{% highlight shell -%}
bundle install
{%- endhighlight %}

## Enable duplication for a subform

Suppose an order has many lines and `:lines` is displayed as a subform. Enable duplication in the association column's form UI options:

{% highlight ruby -%}
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.columns[:lines].form_ui = nil, { duplicate: true }
  end
end
{%- endhighlight %}

Keeping the form UI itself as `nil` tells ActiveScaffold to continue using its default subform while passing `duplicate: true` as an option to that UI.

Alternatively, when the column has no separate form UI options, set the column option:

{% highlight ruby -%}
config.columns[:lines].options[:duplicate] = true
{%- endhighlight %}

If the column already has form UI options, add `duplicate: true` to those options. Form UI options take precedence over the general column options.

Reload an order's create or update form. Each editable line now has a **Duplicate** link alongside its other row actions.

You do not need to add the `:duplicate` action to the controller for this feature. `config.actions << :duplicate` enables duplication of a complete record from the scaffold; duplicating a subform row is configured independently on the association column.

## What happens when a row is duplicated

When you click **Duplicate**, the plugin submits the current field values from that row to the parent controller's `edit_associated` action. ActiveScaffold builds another associated record, fills it from those values, and inserts the rendered row into the subform.

The new row is part of the form only. It is persisted when the parent form is submitted successfully, just like a row created with **Add New**.

Because the values come from the form, unsaved edits made to the original row are included in the duplicate.

## Change values on the duplicated row

Sometimes a field should not be copied, or another value must be recalculated. Override `duplicate_subform_row` in the parent controller, call `super` first to copy the submitted attributes, and then adjust the new record:

{% highlight ruby -%}
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.columns[:lines].form_ui = nil, { duplicate: true }
  end

  protected

  def duplicate_subform_row(record, ...)
    super
    if @column == :lines
      record.serial_number = nil
      record.calculate_total
    end
  end
end
{%- endhighlight %}

`record` is the new associated record. `@column` identifies the association subform that requested it, which is useful when the controller contains more than one duplicable subform.

Clearing unique identifiers, resetting state fields, and recalculating derived amounts are common uses for this hook.

See the [ActiveScaffoldDuplicate plugin page](/plugins/activescaffoldduplicate/) for whole-record duplication and the rest of the plugin's configuration.
