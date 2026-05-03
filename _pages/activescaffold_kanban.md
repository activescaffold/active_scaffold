---
layout: page
title: ActiveScaffoldKanban
date: 2026-05-03 16:13:07 +02:00
permalink: "/plugins/activescaffoldkanban/"
parent: Plugins
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
