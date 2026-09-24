---
layout: page
title: ActiveScaffold Kanban
date: 2026-05-03 16:13:07 +02:00
permalink: "/plugins/activescaffoldkanban/"
parent: Plugins
nav_order: 5
hero_heading: Kanban for ActiveScaffold
hero_lead: Render a kanban board
---

ActiveScaffold Kanban renders scaffold records as cards grouped into board columns. Moving a card to another board column updates the configured model attribute or association, and optional sortable integration persists the order of cards within each column.

### Requirements

- Active Scaffold 3.7.11 or newer
- ActiveScaffold Sortable 3.2.2 or newer
- ActiveScaffold Config List 3.6.0 or newer

Sortable and Config List are runtime dependencies and are installed with the Kanban gem. Their actions are enabled per scaffold only when their corresponding features are needed.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_kanban'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Basic configuration

Enable `:kanban` and select the database column or association used to group the cards:

{% highlight ruby -%}
class TasksController < ApplicationController
  active_scaffold :task do |config|
    config.actions << :kanban
    config.kanban.group_by_column = :status
  end
end
{%- endhighlight %}

Open the index with `?view=kanban` to display the board. To make the board the scaffold's default index view instead, set:

{% highlight ruby -%}
config.kanban.replace_list_view = true
{%- endhighlight %}

Pagination is disabled while rendering the Kanban view so that all records in the current result set can be placed on the board.

### Board columns

The `kanban_columns` helper returns the available board columns as `[label, value]` pairs. By default it resolves values in the same way as a column using the `:select` form UI:

- For a regular model column, set `config.columns[:status].options[:options]` or override `active_scaffold_enum_options`.
- For an association, use `options_for_association_conditions` or `association_klass_scoped` to restrict the available associated records. The association column's `label_method` controls their labels.

These helper overrides support the model-name prefix. You can also replace the complete board-column list:

{% highlight ruby -%}
module TasksHelper
  def task_kanban_columns
    [['Backlog', 'backlog'], ['In progress', 'started'], ['Done', 'done']]
  end
end
{%- endhighlight %}

For an association, the second item in each pair must be the associated record rather than its ID.

### Moving and ordering cards

Dragging a card to another board column calls Active Scaffold's `update_column` action to update `group_by_column`, using the same save and authorization path as in-place editing. If the update fails, the request returns an error and the card moves back to its original position.

Cross-column moves work without enabling the `:sortable` action, but card order is not persisted. Reordering within the same board column is disabled, and the apparent position of a card moved to another column may change when the board reloads.

To persist card order, enable Sortable and configure its position column:

{% highlight ruby -%}
active_scaffold :task do |config|
  config.actions << :kanban
  config.kanban.group_by_column = :status

  config.actions << :sortable
  config.sortable.column = :position
end
{%- endhighlight %}

With this configuration, a move within one board column calls the Sortable `reorder` action. A move between columns updates the grouping value through `update_column` and then persists the submitted order.

### Receive-only columns

A board column can accept cards while preventing its existing cards from being dragged out. Override `kanban_column_receive_only?`; it receives the board-column value, which is the associated record when `group_by_column` is an association:

{% highlight ruby -%}
module TasksHelper
  def task_kanban_column_receive_only?(status)
    status == 'done'
  end
end
{%- endhighlight %}

This helper also supports the model-name prefix, as shown above.

### Config List integration

When the scaffold also enables `:config_list`, users can choose which board columns are visible and arrange their order:

{% highlight ruby -%}
config.actions << :config_list
{%- endhighlight %}

Kanban column preferences are stored separately from the ordinary list-column configuration. List sorting settings are not applied to board columns.

### Card content and actions

Configure the model methods used for card content:

{% highlight ruby -%}
config.kanban.title_method = :name       # default: :to_label
config.kanban.description_method = :summary
{%- endhighlight %}

No description content is shown by default. To customize only the description markup, override `kanban_description(record)` or its model-prefixed form, such as `task_kanban_description(record)`.

To replace the complete card markup, override `_kanban_card.html.erb` in the controller's view directory, for example `app/views/tasks/_kanban_card.html.erb`.

Cards render the scaffold's normal member action links. Inline links whose normal position is `:before`, `:after`, or `:replace` use `config.kanban.links_position`, which defaults to `:table`, while the board is active. An action link can be hidden from the board by assigning an `ignore_method` that checks `@kanban_view`, or by overriding `skip_action_link?`.

The normal create action also works from the Kanban view. After a successful create, the new card is inserted into the board column matching its `group_by_column` value.

### Global defaults

The title method, description method, default-view behavior, and link position can be configured for every Kanban scaffold before controller configurations are built:

{% highlight ruby -%}
ActiveScaffold::Config::Kanban.title_method = :name
ActiveScaffold::Config::Kanban.description_method = :summary
ActiveScaffold::Config::Kanban.replace_list_view = true
ActiveScaffold::Config::Kanban.links_position = :table
{%- endhighlight %}

`group_by_column` must still be configured for each scaffold.

### JavaScript hook

Before a card moves to a different board column, the plugin fires `kanban:beforeChange` on the card. The handler receives an object containing `id` (the record ID) and `column` (the destination value, or the associated record ID for an association).

Return `false` to reject the move. Extra parameters placed in the card's `params` data are merged into the `update_column` request:

{% highlight javascript -%}
$(document).on('kanban:beforeChange', '.kanban .card', function(event, data) {
  if (data.column === 'done' && !window.confirm('Mark this task as done?')) {
    return false;
  }

  $(this).data('params', { changed_from: 'kanban' });
});
{%- endhighlight %}

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_kanban){: .btn .btn-primary}
{: .text-center}
