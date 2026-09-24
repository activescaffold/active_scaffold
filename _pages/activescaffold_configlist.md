---
layout: page
title: ActiveScaffold Config List
date: 2025-02-18 12:04:34.000000000 +01:00
permalink: "/plugins/activescaffoldconfiglist/"
parent: Plugins
nav_order: 2
hero_heading: Config list for ActiveScaffold
hero_lead: Gives users the ability to customize the columns for the list action
---

Gives users the ability to customize which columns are visible in their interface, making data views more flexible, and sorting by multiple columns.

### Description

ActiveScaffold Config List allows users to dynamically select which columns are displayed in ActiveScaffold tables, offering a flexible way to customize data views. Version 4.0 also supports controller-defined, user-saved, and global named views.


### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_config_list'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

Enable column selection in your controller:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions << :config_list
  end
end
{%- endhighlight %}

### Example Code

{% highlight ruby -%}
config.config_list.columns = [:name, :email, :role, :last_login] # available columns
config.config_list.default_columns = [:name, :email]
{%- endhighlight %}

### Named Views

Define reusable list views with their own columns in the controller:

{% highlight ruby -%}
config.config_list.add_view :simple, [:name, :email]
{%- endhighlight %}

Named views can also have a custom label, sorting, and authorization method. When database persistence is enabled, users can save their dynamic configuration under a name, return to it later, and optionally share it as a global view.

### Saving Configurations for Users

Version 4.0 adds the `has_config_lists` model helper. After creating a `ListConfiguration` model with the required storage columns, use the helper to create the user association and the methods that load configurations and list saved views:

{% highlight ruby -%}
class User < ApplicationRecord
  has_config_lists "ListConfiguration",
    association_options: {dependent: :delete_all}
end
{%- endhighlight %}

Configure the controller to use those methods:

{% highlight ruby -%}
config.config_list.save_to_user = :config_list_for
config.config_list.named_views_method = :config_list_views
{%- endhighlight %}

`save_to_user` enables database persistence for the user's current list configuration. `named_views_method` also lets the user save configurations by name and switch between them.

Read the [named views tutorial](/doc/config-list-named-views/) for the complete version 4.0 setup.

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_config_list){: .btn .btn-primary}
{: .text-center}
