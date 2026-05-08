---
title: "show_ui types"
category: "UI Types"
---

There are different show_ui types in ActiveScaffold, some may be useful for some column types only. The show ui types may use options from column’s options hash (conf.columns[:xxx].options = {...}), or an options hash set next to the type (conf.columns[:xxx].show_ui = :yyy, {...}).

## Basic types

### :horizontal

Only for associations, to display show columns of the associated records, instead of a list of labels for the associated record (with to_label or method set in `:label_method` option), the columns are displayed horizontally, as a table. Support subform_columns to display other columns than default show columns on the associated controller.

{% highlight ruby -%}
conf.columns[:risk_items].show_ui = :horizontal, {subform_columns: [:line_item_number, :title,  :applicable_risk, :consequence]}
# or set in column's options, so it's used for the subform and the show
conf.columns[:risk_items].show_ui = :horizontal
conf.columns[:risk_items].options[:subform_columns] = [:line_item_number, :title,  :applicable_risk, :consequence]
{%- endhighlight %}

### :text

It's used automatically in text type columns, display the whole value without truncating, using simple_format method from rails, `:html_options` key from show_ui_options, or Column#options hash, are passed as html_options argument, and the other options are passed as options argument to simple_format too.

### :vertical

Only for associations, to display show columns of the associated records, instead of a list of labels for the associated record (with to_label or method set in `:label_method` option), the columns are displayed vertically. Support subform_columns to display other columns than default show columns on the associated controller.

{% highlight ruby -%}
conf.columns[:risk_items].show_ui = :horizontal, {subform_columns: [:line_item_number, :title,  :applicable_risk, :consequence]}
# or set in column's options, so it's used for the subform and the show
conf.columns[:risk_items].show_ui = :horizontal
conf.columns[:risk_items].options[:subform_columns] = [:line_item_number, :title,  :applicable_risk, :consequence]
{%- endhighlight %}


