---
title: "Search on second order association"
category: "Advanced"
---

Let's suppose a models relationship as follows:

{% highlight ruby -%}
class Employee < ActiveRecord::Base
  has_many :jobs
  has_many :tasks, :through => :jobs
end
class Job < ActiveRecord::Base
  belongs_to: employee
  has_many :tasks
end
class Task < ActiveRecord::Base
  belongs_to: job
end
{%- endhighlight %}

A common need is displaying the 'employee' associated to each 'task' in the 'tasks' list view, and also allowing search based on 'employee'. Following code implements it.

First of all define a 'employee' field for 'task' model (note that there could be no 'job' associated to current 'task' model, or no 'employee' associated to its 'job'):

{% highlight ruby -%}
class Task < ActiveRecord::Base
  [...]
  delegate :employee, :to => :job, :allow_nil => true
{%- endhighlight %}

Add the required "magic" to 'tasks' controller:
1. Add 'employee' to the columns, and exclude it so you don't want it in other actions.
1. Add 'employee' to the search fields.
1. Set the table/column or SQL for the 'employee' search.
1. Set an include in 'job' field.

{% highlight ruby -%}
class TasksController < ApplicationController
  active_scaffold do |config|
    config.columns << :employee
    config.columns.exclude :employee
    [...]
    config.search.columns << :employee
    config.columns[:employee].search_sql = "employees.name"
    config.columns[:employee].includes = {:job => :employee}
    config.columns[:employee].search_ui = :string  # optional
    config.columns[:employee].options[:string_comparators] = true  # optional
  end
end
{%- endhighlight %}

The SQL added during a 'employee' search by the above code looks as follows:

{% highlight sql -%}
[...] LEFT OUTER JOIN `employees` ON `employees`.id = `jobs_tasks`.employee_id WHERE (((LOWER(employees.name) LIKE '%[...]%')))
{%- endhighlight %}

And voilá, the 'tasks' list view displays the 'employee' for each row and also allows search based on its name.
