---
title: Column Overrides (List) Adding html attributes for cells
date: "2025-02-17 15:15:13.000000000 +01:00"
permalink: "/wiki-2/column-overrides-list-adding-html-attributes-for-cells/"
---

Cells in records table already has a class attribute, and you can add more classes with [column](https://github.com/activescaffold/active_scaffold/wiki/API%3A-Column)\#css\_class. If you want to add other html attributes, such as title attribute, you have to define a method in your helper named `#{class_name}_#{column_name}_column_attributes` or `#{column_name}_column_attributes`. This method accepts one argument: the entire record object, and must return a hash with html attributes, as used in rails helpers.

```
module UsersHelper
  def user_roles_column_attributes(record)
    {:title => "Click to edit roles"}
  end
end
```
Also you can override column\_attributes method, which gets two arguments: column object and record object.

```
module UsersHelper
  def column_attributes(column, record)
    if column == :roles
      {:title => "Click to edit roles"}
    else
      {:title => column.label}
    end
  end
end
```
And you can override column\_attributes method in your `ApplicationHelper` file to provide some defaults, or to disable the feature, avoiding some respond\_to? calls

```
module ApplicationHelper
  # set some default attributes and merge them with specific attributes for the column
  def column_attributes(column, record)
    {:title => "#{record.to_label} - #{column.label}"}.merge(super)
  end
  # disable column attributes, avoiding respond_to? methods
  def column_attributes(column, record)
    {}
  end
end
```
