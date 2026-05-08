---
title: "Tabbed Group of Columns"
category: "Advanced"
---

When a group of columns consists in collection associations (`has_many` or `has_and_belongs_to_many`), the records in the subforms can be partitioned in multiple tabs based on the value of a column, which is used as the name of the tab. To do this, start adding a subgroup of columns, and set tabbed_by to the group:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |conf|
    conf.update.columns.add_subgroup 'Skills' do |group|
      group.tabbed_by = :level
      group << [:skill_memberships]
    end
  end
end
{%- endhighlight %}

It will render a select tag with available options for the `tabbed_by` column, to add a new tab with rows for the selected value:

![Screenshot_20241022_160407](/assets/screenshots/tabbed-subform.png)

When new rows are added to a subform in a tab, the column used for the tab will default to the value of the tab. The column used for `tabbed_by` will be in the subform, but it can be setup to be hidden in the subform controller if don't want to allow changing it:

{% highlight ruby -%}
class SkillMembershipsController < ApplicationController
  active_scaffold do |conf|
    conf.columns[:level].form_ui = :hidden
  end
end
{%- endhighlight %}

When a tab is added, the option is hidden from the select tag, as it can't be used to add a new tab. When opening the update form, the current values for the column used for tabs in the associated records will be used to load tabs, and options will be hidden in the select tag to add new tabs.

The available options to add tabs must be defined in a helper named `active_scaffold_tab_options`, which gets column and record. Column is the subgroup of columns. This helper must be overrided to define what available values, although if the tabbed column is an association, it will default to all records for that model. The method must return an array of options, each option with the label and value to be used in the dropdown, and the label is used when adding a tab, and the value to build the html id attribute of some tags in the tabs and subforms. It can be overrided with model name prefix, e.g.:

{% highlight ruby -%}
module UsersHelper
  def user_active_scaffold_tab_options(column, record)
    SkillMembershipsController.active_scaffold_config.columns[:level].options[:options].map do |label, value|
      [label, value || label]
    end
  end
end
{%- endhighlight %}

When the column is an association, each element of the array should be an array of 3 items: label, id and record, so the record can be used to find used tabs, split associated records in the tabs, and assign it to the automatic blank rows in the subforms.

{% highlight ruby -%}
class VtpsController < ApplicationController
  active_scaffold do |conf|
    conf.update.columns.add_subgroup 'Subtasks' do |group|
      group.tabbed_by = :subtask
      group << [:labor_line_items, :other_line_items]
    end
  end
end

module VtpsHelper
  def vtp_active_scaffold_tab_options(column, record)
    record.subtasks.map { |subtask| [subtask.to_label, subtask.id, subtask] }
  end
end
{%- endhighlight %}

There are other helpers which can be overrided, although the default code may work for most of cases. They can be overrided with the same name or prefixed with model name:
* active_scaffold_current_tabs, if the default code to find used tabs doesn't work.  
`def active_scaffold_current_tabs(column, record, tab_options)`  
The `column` argument is the subgroup column with the tabs, `record` is the current record in the form, and `tab_options` are the available tab_options as returned by `active_scaffold_tab_options`. It must return an array, each element of the array must be a 2-items array, with the value of the `tabbed_by` column (the associated record if it's an association, the same as the last item on the arrays returned by `active_scaffold_tab_options`) and the value or id which will be used to generate html id attributes.
* active_scaffold_input_for_tabbed, if the default UI to add new tab doesn't work.  
`def active_scaffold_input_for_tabbed(column, record, subsection_id, tab_options, used_tabs)`  
The `column` argument is the subgroup column with the tabs, `record` is the current record in the form, `subsection_id` is the id attribute of the current subsection (which can be used to generate an id attribute for this tag), `tab_options` are the available tab_options as returned by `active_scaffold_tab_options`, and `used_tabs` are values corresponding for the used tabs (the first item of each array returned by `active_scaffold_current_tabs`.

`Tabbed_by` can be used in the show action, in a group of columns which must be collection associations too:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |conf|
    conf.show.columns.add_subgroup 'Skills' do |group|
      group.tabbed_by = :level
      group << [:skill_memberships]
    end
  end
end
{%- endhighlight %}

It doesn't matter how the columns in the group are rendered, they can be set to display as subform, with `:horizontal` or `:vertical` in the show UI, or just display the label or use any other UI or helper override, the tabbed_by feature just splits the associated records in tabs.
