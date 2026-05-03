---
layout: page
title: ActiveScaffoldBatch
date: 2025-02-18 10:10:11.000000000 +01:00
permalink: "/plugins/activescaffoldbatch/"
parent: Plugins
hero_heading: Batch actions for ActiveScaffold
hero_lead: Perfect for administrative tasks requiring bulk updates or deletions
---

This plugin enables batch actions, allowing users to perform operations on multiple records simultaneously.
Perfect for administrative tasks requiring bulk updates or deletions.

### Description

ActiveScaffoldBatch enables batch actions, allowing users to perform operations on multiple records simultaneously. This is useful for administrative tasks that require bulk updates or deletions, optimizing time and effort for developers.

### Installation

Add the following line to your `Gemfile`:

```
gem 'active_scaffold_batch'
```

Then run:

```
bundle install
```

### Usage & Options

After installation, you can enable batch processing in your ActiveScaffold configuration:

```
ActiveScaffold.set_defaults do |config|
  config.actions << :batch
end
```
In your controller, define the available batch actions:

```
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions << :batch
    config.batch.actions = [:update, :destroy]
  end
end
```
### Example Code

If you want to allow bulk activation of users, you can define a custom action:

```
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions << :batch
    config.batch.actions = [:activate]
    config.batch.configure :activate do |batch|
      batch.label = 'Activate Users'
      batch.confirm = 'Are you sure you want to activate the selected users?'
    end
  end
  def batch_activate
    @records.each do |record|
      record.update(active: true)
    end
    flash[:notice] = "#{@records.size} users activated successfully."
    redirect_to users_path
  end
end
```
