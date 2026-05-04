---
layout: page
title: ActiveScaffoldKanban
date: 2026-05-03 16:13:07 +02:00
permalink: "/plugins/activescaffoldkanban/"
parent: Plugins
nav_order: 5
hero_heading: Kanban for ActiveScaffold
hero_lead: Render a kanban board
---

Adds a new action to render the records in a kanban board instead of normal list,  using a model's column for the kanban columns.

It depends on ActiveScaffoldSortable and ActiveScaffoldConfigList plugins.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_kanban'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

Add `:kanban` to actions.

{% highlight ruby -%}
active_scaffold :model do |conf|
  conf.actions << :kanban
{%- endhighlight %}

Kanban view is used when index action is loaded with `view=kanban` parameter. Default list view can be replaced with kanban with `conf.kanban.replace_list_view = true`.

Then define the column used as kanban columns in the board with `conf.kanban.group_by_column`. It works with both DB column and association. The columns for the board are returned with the `kanban_columns` helper, and it uses the same way to get the values as `:select` form_ui. The helper kanban_columns can be overrided, supporting model prefix, but the default helper supports the same methods to define or change the available values:

- for single columns, define with `options[:options]` in the column, or override `active_scaffold_enum_options` (supports model prefix)
- for associations, define `options_for_association_conditions` or `association_klass_scoped`, model prefix is supported too.

Dragging a card to other column will use `update_column` action, like inplace edit, to change the value. If `update_column` action fails to save, the card is reverted to the original position.

If no position column is defined in sortable, or sortable action is not added, the position on the column can't be changed (drop on the same column reverts to the original position), and the position on the new column is not respected (position may change when kanban is reloaded).

To define a position column, add `:sortable` to `conf.actions`, and define `conf.sortable.column`, then changing the position on the original column will use `reorder` action (as `active_scaffold_sortable`), and dragging to other column will use update_action and will pass the new order to update the order too.

A column may accept items, but don't allow to drag items out. Override `kanban_column_receive_only?` (supports model prefix too) which receives the column value (associated record if the column is an association) and return true for the columns which don't accept to move cards out.

Define the method used for the title with conf.kanban.title_method (defaults to `:to_label`), and method used for description with `conf.kanban.description_method`. The card is rendered with `_kanban_card.html.erb` view partial, which can be overrided to change the html structure of a card, and supports model prefix too. Also the `kanban_description` helper can be defined, which supports model prefix, to change only the body of the card. The actions are rendered calling the kanban_actions helper, which supports model prefix, or actions can be ignored in kanban by defining `ignore_method` in the `action_link` to skip them if `@kanban_view` variable is set, or overriding `skip_action_link?` helper.

A javascript event `kanban:beforeChange` is fired on the card, when it's drop into other column, before sending the request to update the column. The event receives a object argument with 2 properties, the id of the card and the value of the new column (when column is an association, value is an id too). If the event listener returns false, it will reject the change, and the card will revert to the original position. The event listener can set extra params to send to the `update_column` action, with `jQuery(event.target).data('params', {key: value})`.

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_kanban){: .btn .btn-primary}
{: .text-center}