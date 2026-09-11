---
title: "Tutorial: Duplicate rows in ActiveScaffold subforms"
date: "2026-09-11 12:00:00.000000000 +02:00"
categories:
- Tutorials
---

Subforms often contain rows that are almost identical. ActiveScaffoldDuplicate 2.0 lets users copy an existing row, edit only the values that differ, and save everything with the parent form.

Our new [Duplicating rows in subforms tutorial](/doc/duplicate-subform-rows/) shows how to add the **Duplicate** link to a collection subform with one configuration option:

{% highlight ruby -%}
config.columns[:lines].form_ui = nil, { duplicate: true }
{%- endhighlight %}

It also explains when the new row is saved and how to override `duplicate_subform_row` to clear unique fields or recalculate values after the row is copied.

The feature requires ActiveScaffold 4.2 or newer and ActiveScaffoldDuplicate 2.0. Read the [complete tutorial](/doc/duplicate-subform-rows/) to get started.
