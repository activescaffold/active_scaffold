---
title: "Announcing ActiveScaffold Config List 4.0: Named Views"
date: "2026-09-14 09:00:00.000000000 +02:00"
categories:
- Releases
---

**ActiveScaffold Config List 4.0** is now available. This release adds named views, making it easy to offer several useful list layouts and let users return to their preferred column configurations.

### Define named views in the controller

Applications can now define named views alongside the usual default list. Each view can have its own columns, including columns that are not available in the normal configurable list:

{% highlight ruby -%}
config.config_list.add_view :simple, [:number, :status]
{%- endhighlight %}

A block can also be used to give a view a custom label, default sorting, and an authorization method. The complete example is in the tutorial.

Users can switch between the default list and the named views from the list header. The selector can be displayed as a menu of links, radio buttons, or a select field, and positioned to the left, center, or right of the header.

### Let users save their own views

When list configuration is stored in the database, users can now give a configuration a name and return to it later. They can create, rename, and delete their own named views while keeping the ordinary default configuration available.

Two controller settings enable database persistence and expose the user's saved views:

{% highlight ruby -%}
config.config_list.save_to_user = :config_list_for
config.config_list.named_views_method = :config_list_views
{%- endhighlight %}

`save_to_user` names the method used to load and save a configuration. `named_views_method` names the method that returns the views available to the current user and enables saving configurations with a name. Both settings can be applied to one controller or globally in `ActiveScaffold.defaults`.

### Easier model setup

Version 4.0 introduces the `has_config_lists` model helper, which creates the association and both methods used by the settings above:

{% highlight ruby -%}
class User < ApplicationRecord
  has_config_lists "ListConfiguration"
end
{%- endhighlight %}

This replaces most of the custom model code previously needed for database-backed list configurations.

### Share views globally

Applications may optionally allow a saved view to be global. Global views are available to every user, while private views remain specific to the user who created them. Slugs distinguish global and private views even when they have the same display name, and slug generation can be customized when needed.

{% highlight ruby -%}
config.config_list.global_views = true
{%- endhighlight %}

### Fixes

The release also improves behavior when named views are not enabled, handles unnamed list configurations correctly alongside named views, keeps the current URL in sync after a named view is saved, and falls back cleanly to the default view when a requested view does not exist.

### Upgrade

ActiveScaffold Config List 4.0 requires ActiveScaffold 4.2.0 or newer. Update the gem in your `Gemfile` and run Bundler:

{% highlight ruby -%}
gem "active_scaffold_config_list", "~> 4.0"
{%- endhighlight %}

{% highlight shell -%}
bundle update active_scaffold_config_list
{%- endhighlight %}

Read the [named views tutorial](/doc/config-list-named-views/) for the complete setup, including richer controller-defined views, database storage, model options, selector customization, and global views. You can also visit the [ActiveScaffold Config List plugin page](/plugins/activescaffoldconfiglist/).
