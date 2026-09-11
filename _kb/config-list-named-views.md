---
title: "Named views with ActiveScaffold Config List"
category: "Plugins"
date: "2026-09-14 09:00:00.000000000 +02:00"
---

ActiveScaffold Config List 4.0 lets an application provide useful list layouts by name. It can also let users save their own column and sorting configurations as private or global named views.

This feature requires ActiveScaffold 4.2 or newer and ActiveScaffold Config List 4.0.

## Install and enable Config List

Add the plugin to your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold_config_list", "~> 4.0"
{%- endhighlight %}

Then enable the `config_list` action in the controller:

{% highlight ruby -%}
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.actions << :config_list
  end
end
{%- endhighlight %}

Without database persistence, a user's dynamic column configuration is stored in the session.

## Define named views in the controller

Use `add_view` with a name and a list of columns:

{% highlight ruby -%}
config.config_list.add_view :simple, [:number, :status]
{%- endhighlight %}

The name is used in the URL. The columns do not have to be present in `config.list.columns`, so a predefined view can expose a layout that users cannot build with the normal Configure Columns form.

Use a block when a view needs a different label, default sorting, or access control:

{% highlight ruby -%}
config.config_list.add_view :recent_orders do |view|
  view.label = "Recent orders"
  view.columns = [:number, :customer, :status, :total]
  view.sorting = {created_at: :desc}
  view.security_method = :recent_orders_view_authorized?
end
{%- endhighlight %}

The label may also be a symbol, in which case ActiveScaffold translates it. A security method is a controller method and must return true when the current user may open the view:

{% highlight ruby -%}
def recent_orders_view_authorized?
  current_user.can_view_recent_orders?
end
{%- endhighlight %}

The Configure Columns link is hidden while a controller-defined view is selected. These views are application configuration; users switch between them but do not edit them.

## Customize the view selector

Named views appear in the list header. The default selector is a menu of links, but it can also use radio buttons or a select field:

{% highlight ruby -%}
config.config_list.named_views_selector = :links  # default
config.config_list.named_views_selector = :radio
config.config_list.named_views_selector = :select
{%- endhighlight %}

Its position can be changed as well:

{% highlight ruby -%}
config.config_list.named_views_position = :center # default
config.config_list.named_views_position = :left
config.config_list.named_views_position = :right
{%- endhighlight %}

Set one value for each option. These settings may be applied per controller or in `ActiveScaffold.defaults`.

## Create the database model

Database storage is required before users can save named views. A typical migration looks like this:

{% highlight ruby -%}
create_table :list_configurations do |t|
  t.references :user, null: true, foreign_key: true
  t.string :controller_id
  t.text :config_list
  t.text :config_list_sorting
  t.string :view_name
  t.string :slug
  t.timestamps
end
{%- endhighlight %}

`config_list` stores the selected columns and `config_list_sorting` stores their sorting. `controller_id` identifies the scaffold, while `view_name` is needed for named views. The `slug` column and a nullable user association are needed only when global views are enabled.

Define the storage model:

{% highlight ruby -%}
class ListConfiguration < ApplicationRecord
  belongs_to :user, optional: true
  serialize :config_list_sorting, JSON
end
{%- endhighlight %}

If global views will not be enabled, the user reference can be non-null and `optional: true` is unnecessary.

## Easier setup in the user model

The new `has_config_lists` helper creates the `has_many` association and the default methods for finding configurations and listing named views:

{% highlight ruby -%}
class User < ApplicationRecord
  has_config_lists "ListConfiguration",
    association_options: {dependent: :delete_all}
end
{%- endhighlight %}

By default, the helper expects the association to be named `list_configurations` and the model columns to be named `controller_id`, `view_name`, and `slug`. These names can be changed:

{% highlight ruby -%}
has_config_lists "SavedList",
  association_name: :saved_lists,
  association_options: {dependent: :delete_all},
  controller_column: :scaffold,
  view_name_column: :name,
  slug_column: :key
{%- endhighlight %}

The `controller_matcher` option controls how configurations are grouped. Its default, `:controller_name`, shares a configuration between normal, nested, and embedded uses of the same controller. Use `:controller_id` to keep a separate configuration for each nested or embedded context:

{% highlight ruby -%}
has_config_lists "ListConfiguration", controller_matcher: :controller_id
{%- endhighlight %}

It can also be a callable that returns the condition used to find configurations.

## Enable database storage and saved named views

Configure the two methods supplied by `has_config_lists`:

{% highlight ruby -%}
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.actions << :config_list
    config.config_list.save_to_user = :config_list_for
    config.config_list.named_views_method = :config_list_views
  end
end
{%- endhighlight %}

`save_to_user` tells Config List which method loads and saves the current configuration. `named_views_method` tells it which method lists the user's saved views; setting this option also enables the view-name field in the configuration form.

To enable the feature throughout the application, put the same settings in an initializer:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.config_list.save_to_user = :config_list_for
  config.config_list.named_views_method = :config_list_views
end
{%- endhighlight %}

Leaving a view name blank saves the user's ordinary default configuration. Entering a name creates a named view. When an existing user view is selected, its configuration can be edited, renamed, copied under a new name, or deleted. Its selected columns and sorting are saved together.

## Enable global views

Global views use the same database-backed setup, but are available to every user:

{% highlight ruby -%}
config.config_list.global_views = true
{%- endhighlight %}

The configuration form shows a **Global view** option when a new named view is being created. Global records have no user foreign key, which is why the association must be optional.

The slug distinguishes a user's private view from a global view with the same name. By default, Config List prefixes slugs with `user-` or `global-`. To change that convention globally, configure a controller method in `ActiveScaffold.defaults`:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.config_list.slug_builder = :build_config_list_slug
end

def build_config_list_slug(view_name, global_view)
  "#{global_view ? 'shared' : 'user'}-#{view_name.parameterize}"
end
{%- endhighlight %}

Unlike the other settings, `slug_builder` is global. To customize slug creation for only one controller, override `config_list_slug` in that controller instead. If you use the default model helper, keep private-view slugs prefixed with `user-`, because it uses that prefix to distinguish private records.

## Customize persistence further

`has_config_lists` covers the usual database setup. For specialized schemas or access rules, you can define `config_list_for` and `config_list_views` yourself in the user model. The configured methods receive both a controller ID and controller name, and named or global views add keyword arguments for the selected view and attributes.

See the [complete Config List README](https://github.com/activescaffold/active_scaffold_config_list#readme) for the custom-method contracts and examples.
