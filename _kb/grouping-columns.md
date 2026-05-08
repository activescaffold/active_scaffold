---
title: "Grouping Columns"
category: "Advanced"
---

Group of columns can be added in action columns, but not in `list.columns` as they don't make sense in list and will be ignored. To add a group of columns, call `add_subgroup` with the group's label and add the columns to the subgroup like this:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.create.columns.add_subgroup 'Advanced' do |group|
      group << [:column_a, :column_b]
    end
  end
end
{%- endhighlight %}

The columns added to the subgroup will be removed from the action's columns. Groups can be nested too:


{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.create.columns.add_subgroup 'Advanced' do |group|
      group << [:column_a, :column_b]
      group.add_subgroup 'Nested' do |nested|
        nested << [:column_c]
      end
    end
  end
end
{%- endhighlight %}

They can be used in create, update, subform or show, but they don't make sense to use in search (as the search columns only define which columns are used in the conditions of the query), or field search because there is no support for subgroups in field search form.