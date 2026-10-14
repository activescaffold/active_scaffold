---
title: "Four ActiveScaffold Plugin Releases Add UI Adapter Support"
date: "2026-10-14 13:10:00.000000000 +02:00"
categories:
- Releases
---

**ActiveScaffold Duplicate 2.1.0**, **Sortable 3.7.0**, **Batch 3.8.0**, and **Export 3.12.0** are now available. These releases adopt the UI elements API introduced in ActiveScaffold 4.4, allowing Bootstrap, Tailwind CSS, daisyUI, and other adapters to customize plugin markup without replacing plugin views or helpers.

Together with ActiveScaffold Config List 4.1, these releases make the same adapter configuration reusable across ActiveScaffold's core forms and the plugin ecosystem.

------------------------------------------------------------------------

## Style Duplicate's subform action

Duplicate 2.1 exposes the link used to clone a row in an association subform as the `subform_record_duplicate` UI element. Adapters can add button classes, accessibility attributes, or other presentation options while the plugin retains the `dup` class and data attributes required by its JavaScript:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :subform_record_duplicate,
                                      class: "btn btn-sm btn-secondary"
{%- endhighlight %}

This release also makes the subform action helper safe when ActiveScaffold renders an association record without a parent association column. That allows the shared subform partial to be reused by integrations such as ActiveScaffold Batch.

Read the [duplicating rows in subforms tutorial](/doc/duplicate-subform-rows/) or visit the [ActiveScaffold Duplicate plugin page](/plugins/activescaffoldduplicate/).

------------------------------------------------------------------------

## Adapt Sortable containers without replacing partials

Sortable 3.7 exposes sortable list and association-subform wrappers as the `sortable_container` UI element. The same adapter definition applies in both places:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :sortable_container,
                                      class: "overflow-auto"
{%- endhighlight %}

Adapter attributes are merged with the `sortable-container` class and `data-*` attributes used for drag-and-drop behavior, so styling does not interfere with reordering.

The release also updates Sortable's development and test integration for ActiveScaffold 4.4, including ActiveScaffold's Active Record hash-based sorting clauses.

Visit the [ActiveScaffold Sortable plugin page](/plugins/activescaffoldsortable/) for configuration examples covering ordinary lists, association subforms, `acts_as_list`, nested sets, and Ancestry.

------------------------------------------------------------------------

## Keep Batch forms consistent with ActiveScaffold

Batch 3.8 reuses ActiveScaffold's standard form UI elements throughout its create and update forms. Adapter definitions for elements such as `form`, `fields_container`, `form_element`, `form_attribute`, `form_control`, and form footer controls therefore apply to Batch automatically.

The release adds one Batch-specific element, `batch_create_add_rows`, for the remote link that adds blank rows to a multiple-row Batch Create form:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :batch_create_add_rows,
                                      class: "btn btn-sm btn-secondary"
{%- endhighlight %}

Batch controls also pass a `batch_role` to the shared `form_control` element. An adapter can use it to distinguish the batch scope, update operator and value, numeric or date options, and Batch Create row count when those controls need specialized styling.

Batch 3.8 also includes fixes for numeric and date batch updates and improves the markup shared with ActiveScaffold's horizontal subforms.

See the [ActiveScaffold Batch plugin page](/plugins/activescaffoldbatch/) for setup, safety considerations, action modes, and the complete adapter context reference.

------------------------------------------------------------------------

## Style Export options through the adapter

Export 3.12 reuses ActiveScaffold's `fields_container`, `form_element`, and `form_attribute` elements for its options form. It adds two plugin-specific elements: `export_option` wraps an individual option, while `export_option_row` groups related options.

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :export_option,
                                      class: "form-check"
ActiveScaffold.add_element_attributes :export_option_row,
                                      class: "d-flex gap-3"
{%- endhighlight %}

This lets an adapter style the export form without replacing its partial. The release also ensures the plugin's locale files are included in the packaged gem.

Visit the [ActiveScaffold Export plugin page](/plugins/activescaffoldexport/) for CSV and XLSX setup, configuration options, and customization hooks.

------------------------------------------------------------------------

## Upgrade

All four releases require ActiveScaffold 4.4.0 or newer. Update the entries for the plugins your application uses:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4.0"
gem "active_scaffold_duplicate", "~> 2.1"
gem "active_scaffold_sortable", "~> 3.7"
gem "active_scaffold_batch", "~> 3.8"
gem "active_scaffold_export", "~> 3.12"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold active_scaffold_duplicate active_scaffold_sortable active_scaffold_batch active_scaffold_export
{%- endhighlight %}

For the complete adapter API, element registry, and customization examples, read [Customizing UI Markup and Integrating CSS Frameworks](/doc/framework-ui/).

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
