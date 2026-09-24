---
layout: page
title: ActiveScaffold Export
date: 2025-02-18 11:34:51.000000000 +01:00
permalink: "/plugins/activescaffoldexport/"
parent: Plugins
nav_order: 3
hero_heading: Export for ActiveScaffold
hero_lead: An essential tool for generating reports or sharing data with external systems
---

ActiveScaffold Export adds an **Export** action to your ActiveScaffold controllers. Users can choose the columns to include and download either the current page or all matching records. The plugin preserves the list's current filters and sorting.

CSV export works out of the box and streams large result sets in batches. XLSX export is available when `caxlsx_rails` is installed.

## Installation

Add the plugin to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_export'
{%- endhighlight %}

To also export Excel-compatible `.xlsx` files, add:

{% highlight ruby -%}
gem 'caxlsx_rails'
{%- endhighlight %}

Install the gems:

{% highlight shell -%}
bundle install
{%- endhighlight %}

## Enable exporting

Add the `:export` action inside the controller's `active_scaffold` block. You can also select the available columns and choose which ones are initially deselected in the export form:

{% highlight ruby -%}
class ProductsController < ApplicationController
  active_scaffold :product do |conf|
    conf.actions.add :export
    conf.export.columns = %w[name category price created_at]
    conf.export.default_deselected_columns = %w[created_at]
  end
end
{%- endhighlight %}

By default, the Export link opens a form where the user can:

- select the columns to export;
- export the current page or all matching records;
- include or omit the header row;
- change the CSV delimiter; and
- choose CSV or XLSX when XLSX support is installed.

## Configuration

Configure the export action inside the same `active_scaffold` block:

{% highlight ruby -%}
conf.export.show_form = true
conf.export.allow_full_download = true
conf.export.default_full_download = true
conf.export.default_file_format = 'csv'
conf.export.default_delimiter = ';'
conf.export.default_skip_header = false
conf.export.force_quotes = true
{%- endhighlight %}

| Setting | Purpose | Default |
| --- | --- | --- |
| `columns` | Columns available for export | The action's default columns |
| `default_deselected_columns` | Columns initially unchecked in the form | None |
| `show_form` | Show the options form before downloading | `true` |
| `allow_full_download` | Let users choose between the current page and all results | `true` |
| `default_full_download` | Select all matching records by default | `true` |
| `default_file_format` | Initial format: `'csv'` or `'xlsx'` | XLSX when available; otherwise CSV |
| `default_delimiter` | CSV column separator | `','` |
| `default_skip_header` | Omit the header row by default | `false` |
| `force_quotes` | Quote every field in CSV output | `false` |

Set `show_form` to `false` to download immediately using the configured defaults. Set `allow_full_download` to `false` to prevent users from changing the `default_full_download` choice.

## Customize exported values

Define a helper named `<column>_export_column` to customize a column's exported value. The helper receives the record and selected format:

{% highlight ruby -%}
def price_export_column(record, format)
  value = record.price.to_f
  return value unless format == :xlsx

  [value, { format_code: '$#,##0.00' }]
end
{%- endhighlight %}

For XLSX, an override may return `[value, style_options]` to apply `caxlsx` formatting. You can also configure XLSX options directly on a column:

{% highlight ruby -%}
conf.columns[:price].export_options = {
  xlsx: { format_code: '$#,##0.00', width: 14 }
}
{%- endhighlight %}

Header labels can be changed by overriding `format_export_column_header_name`. The [helper overrides documentation](https://github.com/activescaffold/active_scaffold_export/wiki/Helper-Overrides) describes the other formatting hooks.

## XLSX notes

XLSX support requires `caxlsx_rails`. When it is installed, XLSX becomes the default format unless you set `default_file_format` to `'csv'`.

Unlike CSV, XLSX output cannot be streamed: the complete workbook must be serialized and zipped before it is downloaded. Use CSV for very large exports.

The worksheet name comes from the ActiveScaffold label. Forbidden characters are replaced with `-`, and the result is limited to Excel's 31-character maximum. Override `worksheet_name` in the controller to customize it:

{% highlight ruby -%}
def worksheet_name(options = {})
  super replace: '_', omission: ''
end
{%- endhighlight %}

See [Cell Format Options](https://github.com/activescaffold/active_scaffold_export/wiki/Cell-Format-Options) for XLSX styling details.

## Authorization

Export uses ActiveScaffold's read authorization by default. The plugin adds two controller actions:

- `show_export` displays the options form;
- `export` generates the download.

Override `export_authorized?` when an application needs a more restrictive rule. `show_export_authorized?` delegates to it by default.

## Grouped search

Grouped field-search results can also be exported. In this mode, the plugin exports the grouped columns and calculated list columns instead of the normal export column set. Column overrides use the `<column>_grouped_export_column` naming convention.

For every available option, see the [Export Configuration reference](https://github.com/activescaffold/active_scaffold_export/wiki/Export-Configuration).

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_export){: .btn .btn-primary}
{: .text-center}
