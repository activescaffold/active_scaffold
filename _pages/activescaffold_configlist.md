---
layout: page
title: ActiveScaffoldConfigList
date: 2025-02-18 12:04:34.000000000 +01:00
permalink: "/plugins/activescaffoldconfiglist/"
parent: Plugins
---

ActiveScaffoldConfigList
========================

Gives users the ability to customize which columns

ActiveScaffoldConfigList
------------------------

Gives users the ability to customize which columns are visible in their interface, making data views more flexible.

### Description

ActiveScaffoldConfigList allows users to dynamically select which columns are displayed in ActiveScaffold tables, offering a flexible way to customize data views.


### Installation

```
gem 'active_scaffold_config_list'
```

Then run:

```
bundle install
```

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
config.config_list.available_columns = [:name, :email, :role, :last_login]
config.config_list.default_columns = [:name, :email]
```
