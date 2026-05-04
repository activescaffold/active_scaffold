---
layout: page
title: ActiveScaffold Child Memberships
date: 2025-02-18 10:44:02.000000000 +01:00
permalink: "/plugins/activescaffoldchildmemberships/"
parent: Plugins
nav_order: 6
hero_heading: Child memberships form UI for ActiveScaffold
hero_lead: Ideal for applications requiring customizable ordering, such as task prioritization
---

Adds a new form UI, `:child_memberships`, to manage a many-to-many association across multiple related records
simultaneously, displayed as a table where each row is a related record and each column is a membership option.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_child_memberships'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

ActiveScaffold allows to edit memberships on one record with :select form_ui, for either has_and_belongs_to_many, or has_many through. For example, using :select in :roles column with any of these examples would work in the same way:

{% highlight ruby -%}
class User < ApplicationRecord
  has_and_belongs_to_many :roles
end

class User < ApplicationRecord
  has_many :role_memberships
  has_many :roles, through: :role_memberships
end

class RoleMembership < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
{%- endhighlight %}

But sometimes you may have User model grouped in other model, with has_many association, and may want to edit memberships for all the users in the group.

{% highlight ruby -%}
class Group < ApplicationRecord
  has_many :users
end
{%- endhighlight %}

This form UI `:child_memberships` can be used in a roles `has_many` through association. The source of the through association must be a `has_and_belongs_to_many` or `has_many` through association.

{% highlight ruby -%}
class Group < ApplicationRecord
  has_many :users
  has_many :roles, through: :users
end
class GroupsController < ApplicationController
  active_scaffold :group do |conf|
    conf.update.columns = [:name, :roles]
    conf.columns[:roles].form_ui = :child_memberships
  end
end
{%- endhighlight %}

Then you get a table, with all users in the group in the rows, and roles in the columns. Only the assigned roles are in the columns by default, and new column can be added with a select tag to pick a new role to assign to users:

![image](/assets/img/child_memberships_ui.png)

It's possible to add new columns. The form UI used to select the record of the new columns can be customized, with options for the form_ui (or column's options), with the key `:add_column_ui`, for example to use RecordSelect:

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {add_column_ui: :record_select}
{%- endhighlight %}

If no form_ui is defined with `:add_column_ui`, it defaults to `:select`. If ui options must be passed to the form_ui, they can be added using an array with the form UI and the options hash:

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {add_column_ui: [:select, {include_blank: 'Pick one'}]}
{%- endhighlight %}

The method used for the label in the rows is defined with `:label_method`, defaults to `:to_label`. For example, to use `short_name` method of Role model:

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {label_method: :short_name}
{%- endhighlight %}

The method used for the label in the rows is defined with `:child_label_method`, defaults to `:to_label`. For example, to use `first_name` method of User model:

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {child_label_method: :first_name}
{%- endhighlight %}

The label of the link to add a new column uses `:add_label` translation key, in the `:active_scaffold` scope. It can be changed to a string, skipping the translation, or other symbol to use other translation key, in the `:active_scaffold` scope. The translation can use `%{model}` variable to display the name of the associated model.

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {add_label: 'Add other role'}
{%- endhighlight %}

If new columns are not allowed, it can be disabled using `add_label: false`:

{% highlight ruby -%}
    conf.columns[:roles].form_ui = :child_memberships, {add_label: false}
{%- endhighlight %}

### Overriding Helpers

The helper `active_scaffold_child_memberships_members` can be overrided to change the default columns rendered, instead of the assigned records only. For example to render all available roles:

{% highlight ruby -%}
def active_scaffold_child_memberships_helper(column, row_records)
  column.association.klass.all
end
{%- endhighlight %}

The helper can use model prefix too:

{% highlight ruby -%}
def group_active_scaffold_child_memberships_helper(column, row_records)
  column.association.klass.all
end
{%- endhighlight %}

To change the record selector for new columns, the helper `active_scaffold_child_memberships_new_column` can be overrided instead of using `:add_column_ui`. It supports model prefix too. The field should be rendered disabled, as it's a template to be cloned when the add column link is clicked:

{% highlight ruby -%}
def active_scaffold_child_memberships_new_column(column, name, source_col, ui_options)
  if column == :roles
    select_tag name, options_from_collection_for_select(Role.allowed_for(current_login), :id, :name), id: nil, disabled: true
  else
    super
  end
end
{%- endhighlight %}

Also, the available records can be changed with the usual methods, `options_for_association_conditions` and `association_klass_scoped`, they receive the source association of the has_many through association (`:roles` in the example), and an empty record of the through association.

To change how checkboxes are rendered, for example, adding extra content, the helper `active_scaffold_child_memberships_checkbox` can be overrided. It supports model prefix too. The argument child is the record of the row, and member is the record of the column.

{% highlight ruby -%}
def active_scaffold_child_memberships_checkbox(column, source_column, child, member, name:, value:)
  if column == :roles
    safe_join [super, content_tag(:span, member.state_for(child))] 
  else
    super
  end
end
{%- endhighlight %}

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_sortable){: .btn .btn-primary}
{: .text-center}
