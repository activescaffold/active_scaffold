---
layout: page
title: ActiveScaffold Sortable
date: 2025-02-18 10:44:02.000000000 +01:00
permalink: "/plugins/activescaffoldsortable/"
parent: Plugins
nav_order: 1
hero_heading: Sortable action for ActiveScaffold
hero_lead: Drag-and-drop ordering for lists, association subforms, and trees
---

ActiveScaffold Sortable adds AJAX drag-and-drop ordering to Active Scaffold lists and association subforms. It supports ordinary ordered lists, automatic configuration for `acts_as_list` models, and sibling ordering in nested-set and Ancestry trees.

### Requirements

- Ruby 2.0 or newer
- Active Scaffold 4.0.0.rc1 or newer
- A Rails version supported by the selected Active Scaffold version
- jQuery UI Sortable on pages that use the plugin

For Rails 3 applications, use an `active_scaffold_sortable` 3.2.x release.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_sortable'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

The engine automatically registers the Active Scaffold action, route, JavaScript, stylesheet, and view overrides.

### Ordered lists

#### With `acts_as_list`

Add a position column and configure the model with [`acts_as_list`](https://github.com/brendon/acts_as_list):

{% highlight ruby -%}
class AddPositionToEntries < ActiveRecord::Migration[6.0]
  def change
    add_column :entries, :position, :integer
    add_index :entries, :position
  end
end
{%- endhighlight %}

{% highlight ruby -%}
class Entry < ApplicationRecord
  acts_as_list
end
{%- endhighlight %}

The plugin detects `acts_as_list`, enables the `:sortable` action, and uses the model's configured position column. No Active Scaffold controller configuration is required.

Scopes configured in `acts_as_list` still define separate logical lists. A rendered Active Scaffold list should contain records from only one scope, so dragging cannot mix independent lists.

#### Without `acts_as_list`

Sorting can use any persisted column that accepts one-based integer positions. Enable the action and select the column explicitly:

{% highlight ruby -%}
class EntriesController < ApplicationController
  active_scaffold :entry do |config|
    config.actions << :sortable
    config.sortable.column = :position
  end
end
{%- endhighlight %}

After every drop, the visible records receive consecutive positions beginning at `1`. The plugin updates records directly with `update_all`, so model validations and callbacks do not run. It also updates `updated_at` when that column exists. The reorder action uses Active Scaffold's update authorization check.

### Sortable association subforms

A collection association is draggable in a create or update form when the associated model's Active Scaffold configuration includes `:sortable`. This works whether sorting was enabled automatically by `acts_as_list` or configured manually:

{% highlight ruby -%}
class TasksController < ApplicationController
  active_scaffold :task do |config|
    config.actions << :sortable
    config.sortable.column = :position
  end
end
{%- endhighlight %}

For example, a `Project` form that renders a `has_many :tasks` subform will allow its task rows to be reordered. Dragging changes the hidden position fields in the form; the new order is persisted when the parent form is submitted, rather than through a separate reorder request. New associated records without a position are placed after the highest existing position.

Only collection associations are sortable. The associated scaffold may omit the `:list` action when sorting is needed only in a subform.

### Tree models

Tree support reorders nodes only among their current siblings. It does not move a node to a different parent.

#### Nested sets (`awesome_nested_set`)

Models using [`awesome_nested_set`](https://github.com/collectiveidea/awesome_nested_set) are detected automatically:

{% highlight ruby -%}
class Category < ApplicationRecord
  acts_as_nested_set
end
{%- endhighlight %}

The plugin enables `:sortable`, uses the model's configured left column, and calls the nested-set movement methods to preserve valid left and right bounds. Root nodes can also be reordered as siblings.

Detection is API-based. Another nested-set implementation may work if it provides `nested_set_scope`, `left_column_name`, `self_and_siblings`, `move_left`, and `move_right`, but `awesome_nested_set` is the supported integration.

#### Ancestry

Ancestry models are recognized during reordering, but sorting is not enabled automatically. Add a separate position column and configure it explicitly:

{% highlight ruby -%}
class Category < ApplicationRecord
  has_ancestry
end
{%- endhighlight %}

{% highlight ruby -%}
class CategoriesController < ApplicationController
  active_scaffold :category do |config|
    config.actions << :sortable
    config.sortable.column = :position
  end
end
{%- endhighlight %}

Both root nodes and children can be reordered within the first submitted record's sibling set. Do not use the `ancestry` column as the sortable column: it stores a path, not a sibling position.

### Configuration

#### Drag handle

The whole row is the drag handle by default. To add a dedicated handle column at the beginning or end of the list:

{% highlight ruby -%}
config.sortable.add_handle_column = :first
# or
config.sortable.add_handle_column = :last
{%- endhighlight %}

The accepted values are `:first`, `:last`, and `false`/`nil`.

#### Refresh after reordering

The default response only reapplies alternating row styles. Refresh the entire list after each reorder when other displayed values depend on the order:

{% highlight ruby -%}
config.sortable.refresh_list = true
{%- endhighlight %}

#### Advanced DOM options

`config.sortable.options` is merged into the sortable container's `data-*` attributes. The supported overrides are integration hooks for custom Active Scaffold markup:

{% highlight ruby -%}
config.sortable.options = {
  tag: "> tr",                     # selector for draggable items
  handle: ".my-drag-handle",       # selector that starts dragging
  content_selector: ".my-records", # sortable content in the container
  key: "as_entries-tbody",         # serialized parameter base
  format: "^[^_-].*-(.*)-row$",    # extracts the record ID from a row ID
  with: "scope_id=42"               # extra reorder request parameters
}
{%- endhighlight %}

These options are not a general pass-through for every jQuery UI Sortable setting. If you override `key`, keep it aligned with the parameter name expected by the reorder action.

You can also define defaults for every sortable scaffold in an initializer, before Active Scaffold configurations are built:

{% highlight ruby -%}
ActiveScaffold::Config::Sortable.add_handle_column = :first
ActiveScaffold::Config::Sortable.refresh_list = true
ActiveScaffold::Config::Sortable.options = { handle: ".my-drag-handle" }
{%- endhighlight %}

### Effects on the Active Scaffold list

Enabling `:sortable` also:

- Disables pagination so every draggable record is present in one list
- Orders the list by the sortable column in ascending order
- Disables sorting by other columns
- Hides the sortable column from normal action columns, while retaining it as a hidden field in subforms

The browser submits only rendered rows. Filters and nested views therefore update only the visible subset, while records not shown retain their stored positions. In an ordinary list this can produce duplicate positions. Keep each sortable view within one logical list or sibling set, and use filtering with care.

### Support

For help, use the [Active Scaffold discussion group](https://groups.google.com/group/activescaffold) or [open an issue](https://github.com/activescaffold/active_scaffold_sortable/issues).

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_sortable){: .btn .btn-primary}
{: .text-center}
