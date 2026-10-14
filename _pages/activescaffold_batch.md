---
layout: page
title: ActiveScaffold Batch
date: 2025-02-18 10:10:11.000000000 +01:00
permalink: "/plugins/activescaffoldbatch/"
parent: Plugins
nav_order: 4
hero_heading: Batch actions for ActiveScaffold
hero_lead: Perfect for administrative tasks requiring bulk updates or deletions
---

This plugin enables batch actions, allowing users to create, update, or delete multiple records simultaneously. It is intended for administrative workflows where the affected scope is explicit and reviewable.

### Requirements

- Active Scaffold 4.4.0 or newer for ActiveScaffold Batch 3.8
- A Ruby and Rails version supported by the selected Active Scaffold version

### Description

ActiveScaffold Batch provides three independent actions: `batch_create`, `batch_update`, and `batch_destroy`. Enable only the actions appropriate for a controller.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_batch'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

It provides three actions: `batch_create`, `batch_update`, and `batch_destroy`.
You can enable batch processing globally:

{% highlight ruby -%}
ActiveScaffold.set_defaults do |config|
  config.actions << :batch_update
end
{%- endhighlight %}

Or adding them in your controller:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions.add :batch_update
    config.actions.add :batch_destroy
  end
end
{%- endhighlight %}

Batch Update and Batch Destroy can target every record in the current filtered list. If the scaffold also enables the `mark` action, they can instead target only marked records.

### Batch Create

Batch Create has two modes. Without `default_batch_by_column`, it displays a multiple-row creation form. The user starts with one blank record and can add more rows before submitting them together:

{% highlight ruby -%}
config.actions.add :batch_create
config.batch_create.layout = :vertical # or :horizontal
{%- endhighlight %}

When `default_batch_by_column` is configured, the form creates one record for every selected value of that column while sharing the other entered attributes. For example, this creates one player for each selected team:

{% highlight ruby -%}
config.actions.add :batch_create
config.batch_create.default_batch_by_column = :team
{%- endhighlight %}

The batch column may be a `belongs_to` association or a scalar column. Scalar values are entered one per line. By default, all records are validated and created in one transaction; if one fails, none are saved.

{% highlight ruby -%}
config.batch_create.run_in_transaction = true
config.batch_create.list_mode_enabled = true
{%- endhighlight %}

Set `run_in_transaction` to `false` to retain successful rows when another fails, or to `:validate_first` to validate all rows before saving any of them.

### Batch Update

Each editable column has an operator. `NO_UPDATE` leaves it untouched and `REPLACE` assigns the entered value. Numeric columns also support addition, subtraction, multiplication, and division using absolute or percentage operands; date columns support addition and subtraction.

{% highlight ruby -%}
config.actions.add :batch_update
config.batch_update.process_mode = :update
config.batch_update.list_mode_enabled = true
{%- endhighlight %}

The default `:update` mode processes each record with authorization, validations, and callbacks. The optional `:update_all` mode performs direct SQL updates and skips model callbacks and validations.

### Batch Destroy

{% highlight ruby -%}
config.actions.add :batch_destroy
config.batch_destroy.process_mode = :delete
{%- endhighlight %}

The default `:delete` mode processes records individually. The optional `:delete_all` mode uses direct SQL and skips model callbacks. List-scoped actions affect the complete filtered result, not only the visible page, so marked-record scope is safer when users should select every affected record explicitly.

### UI adapter support

ActiveScaffold Batch 3.8 reuses ActiveScaffold 4.4's standard form elements. See [ActiveScaffold's complete UI element reference](/doc/framework-ui/#complete-ui-element-reference) for `form`, `form_title`, `fields_container`, `form_element`, `form_attribute`, `form_control`, form footer controls, and the other shared elements.

Batch defines only one plugin-specific element:

| Element | Type | Used for |
|---|---|---|
| `batch_create_add_rows` | Attributes only | Remote link that adds blank rows to a multiple-row Batch Create form. |

For example, an adapter can customize the Batch-specific add-row link without replacing its template:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :batch_create_add_rows,
                                      class: "btn btn-sm btn-secondary"
{%- endhighlight %}

Adapter attributes are merged with the remote-link behavior required by the plugin.

Batch-specific inputs use the shared `form_control` element. Its proc receives the usual `column` and `form_ui` context plus `batch_role`, which identifies `batch_scope`, `batch_update_operator`, `batch_update_value`, `batch_update_numeric_option`, `batch_update_date_amount`, `batch_update_date_unit`, or `batch_create_row_count`. This lets an adapter distinguish these controls when necessary without adding a separate registry element for each one.

The shared elements use the same definitions as ordinary ActiveScaffold forms, keeping core and Batch forms consistent.

### Custom batch actions

If you want to allow bulk activation of users, you can define a custom action:

{% highlight ruby -%}
class UsersController < ApplicationController
  include ActiveScaffold::Actions::BatchBase

  active_scaffold :user do |config|
    config.action_links.collection.add :batch_activate, label: 'Activate Users',
      confirm: 'Are you sure you want to activate the selected users?',
      parameters: {batch_scope: 'marked'}
  end

  def batch_activate
    batch_action
  end

  protected

  def batch_activate_marked
    activated = 0
    each_marked_record do |record|
      if record.update(active: true)
        record.as_marked = false
        activated += 1
      else
        error_records << record
      end
    end
  end
end
{%- endhighlight %}

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_batch){: .btn .btn-primary}
{: .text-center}
