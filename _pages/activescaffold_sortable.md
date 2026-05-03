---
layout: page
title: ActiveScaffoldSortable
date: 2025-02-18 10:44:02.000000000 +01:00
permalink: "/plugins/activescaffoldsortable/"
parent: Plugins
hero_heading: Sortable action for ActiveScaffold
hero_lead: Ideal for applications requiring customizable ordering, such as task prioritization
---

Allows users to drag and drop records within a list to reorder them easily.
Ideal for applications requiring customizable ordering, such as task prioritization.

### Description

ActiveScaffoldSortable allows users to reorder records within a list using drag-and-drop functionality. This is particularly useful in applications where item ordering is significant, such as task prioritization or image galleries.

### Installation

```
gem 'active_scaffold_sortable'
```

Then run:

```
bundle install
```

### Usage & Options

Ensure your model has a `position` column to store the order:

```
class AddPositionToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :position, :integer
  end
end
```
Enable sortable functionality in your controller:

```
class TasksController < ApplicationController
  active_scaffold :task do |config|
    config.actions << :sortable
    config.sortable.column = :position
  end
end
```
