---
layout: page
title: ActiveScaffoldConfigList
date: 2025-02-18 12:04:34.000000000 +01:00
permalink: "/plugins/activescaffoldconfiglist/"
parent: Plugins
hero_heading: Config list for ActiveScaffold
hero_lead: Gives users the ability to customize the columns for the list action
---

Gives users the ability to customize which columns are visible in their interface, making data views more flexible, and sorting by multiple columns.

### Description

ActiveScaffoldConfigList allows users to dynamically select which columns are displayed in ActiveScaffold tables, offering a flexible way to customize data views.


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

```
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions << :config_list
  end
end
```
### Example Code

```
config.config_list.columns = [:name, :email, :role, :last_login] # available columns
config.config_list.default_columns = [:name, :email]
```
