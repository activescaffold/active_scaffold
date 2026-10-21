---
title: "ActiveScaffold MCP Read Tools: List, Show, and Output"
date: "2026-10-21 11:14:00.000000000 +02:00"
category: "MCP"
---

ActiveScaffold MCP 0.1.1 generates read-only list and show tools. Both reuse ActiveScaffold configuration, authorization, and a common structured-data presenter.

Start with [Getting Started with ActiveScaffold MCP](/doc/active-scaffold-mcp/) if the gem and its tools are not configured yet.

## List tools

A generated list tool reuses ActiveScaffold's `do_list` behavior and returns records with pagination metadata:

{% highlight json -%}
{
  "records": [],
  "page": 2,
  "total_count": 57,
  "total_pages": 3
}
{%- endhighlight %}

Every list tool accepts bounded `limit` and `page` arguments. It can also expose selected column filters, named list filters, full-text search, sorting, and Config List views.

### Column filters

Configure each column and the operators allowed for it:

{% highlight ruby -%}
config.mcp.expose :list,
                  filter_columns: {
                    id: %i[equal in],
                    status: %i[equal not_equal in not_in],
                    created_at: %i[between not_between null not_null]
                  }
{%- endhighlight %}

Supported operators are `equal`, `not_equal`, `in`, `not_in`, `between`, `not_between`, `null`, and `not_null`. They produce descriptive properties such as `status`, `status_not`, `status_in`, `created_at_from`, and `created_at_to` in the tool input schema.

Reusable column sets can add filters without listing every column:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.mcp.filter_column_sets = {
    foreign_keys: :in,
    timestamps: :range
  }
end

config.mcp.expose :list,
                  filter_column_sets: {
                    foreign_keys: :in,
                    timestamps: :range
                  }
{%- endhighlight %}

The available sets are `foreign_keys`, `dates`, and `timestamps`. Each set requires an explicit operator. For a polymorphic `belongs_to`, selecting its foreign key also exposes the corresponding type column.

When `config.mcp.filter_column_sets` is assigned inside `ActiveScaffold.defaults`, those sets are inherited by every exposed list action that does not configure `filter_column_sets` itself. `foreign_keys` selects every column whose name ends in `_id`; `dates` selects `date` columns; and `timestamps` selects `datetime`, `timestamp`, and `timestamptz` columns. Explicit `filter_columns` and selected sets are combined, with an explicitly configured column taking precedence.

### Named filters and search

Expose selected ActiveScaffold list filters by name, or expose every configured filter:

{% highlight ruby -%}
config.mcp.expose :list, filters: %i[open overdue]
# or
config.mcp.expose :list, filters: :all
{%- endhighlight %}

Filter and filter-option authorization continues to apply. A requested filter that is disallowed in the current context causes the tool to return an error instead of silently broadening the query.

When ActiveScaffold's search action is enabled, the list tool also gets a `search` argument using `config.search.columns`. Disable it for MCP when it is not appropriate:

{% highlight ruby -%}
config.mcp.list.search = false
{%- endhighlight %}

### Sorting

List tools expose sorting for columns allowed by the ActiveScaffold list configuration. The generated description identifies sortable columns and the default order. Sorting, searching, filters, and pagination can be combined in one call.

### Named list views

When the controller enables ActiveScaffold Config List, the generated list tool can expose a `list_view` argument. Selecting a view changes the returned columns and default sorting.

Configured view names become an enum when they are the complete set. If user-saved views are enabled, ActiveScaffold MCP also generates a `<list tool name>_views` tool. It returns configured and saved views available to the current user, including the exact `value` to pass to `list_view`.

Explicit MCP `columns` define the default output when `list_view` is omitted. When a caller selects a view, that view supplies the output columns and default sorting for the call. An explicit `sort` argument takes precedence over the view's default sorting.

Named-view security methods run in the generated tool. Put methods needed by both HTTP and MCP execution in a shared module and add it to the MCP action.

## Show tools and alternative identifiers

The show generator creates a read-only `show_<singular-resource>` tool. By default it requires the model's primary key. Configure `lookup_columns` when the application has meaningful identifiers such as a case number:

{% highlight ruby -%}
config.mcp.show.lookup_columns = %i[case_number external_id]
{%- endhighlight %}

The caller must supply exactly one of `id`, `case_number`, or `external_id`. A lookup must resolve to exactly one authorized record; missing and ambiguous lookups return an error.

The result contains one serialized record:

{% highlight json -%}
{
  "record": {
    "id": 7,
    "case_number": "CASE-1042",
    "subject": "Unable to sign in"
  }
}
{%- endhighlight %}

Composite primary keys are not supported by the show tool in version 0.1.1.

## Output columns

When MCP `columns` are not configured, list and show tools reuse the visible columns from `config.list.columns` and `config.show.columns`. The model primary key is always considered for output, subject to the same authorization checks as every other column.

Explicit MCP output columns pass through the model's class-level `authorized_for?` check. Every value also passes through the individual record's `authorized_for?` check before serialization.

Virtual HTML columns are not rendered through view helpers. A column is included when it is an association or the record has a public method for it that can be called without required arguments. This prevents HTML badges, links, and other browser-specific output from leaking into MCP results. Model methods returning `nil` remain present as JSON `null`.

## Association output

A singular association is returned as an object with `id` and `label`, or as `null`. Labels use the associated record's `to_label`. For example, expose a singular `customer` association and an unlimited `tags` collection:

{% highlight ruby -%}
config.columns[:tags].associated_limit = nil
config.mcp.expose :show, columns: %i[id customer tags]
{%- endhighlight %}

The associations are serialized inside the show tool's `record` object. The same values appear inside each element of a list tool's `records` array:

{% highlight json -%}
{
  "record": {
    "id": 42,
    "customer": {
      "id": 7,
      "label": "Acme"
    },
    "tags": [
      {"id": 2, "label": "Important"},
      {"id": 3, "label": "Open"}
    ]
  }
}
{%- endhighlight %}

A missing singular association is `null`; an empty unlimited collection is an empty array:

{% highlight json -%}
{
  "customer": null,
  "tags": []
}
{%- endhighlight %}

ActiveScaffold's `associated_limit` and `associated_number` settings also apply. Unless the application changes ActiveScaffold's column defaults, collection associations use a limit of `3` with counting enabled:

- An unlimited collection is returned as an array.
- A positive limit returns `records` and `count` when the complete collection fits.
- A truncated collection uses `first_records`; its count is exact when `associated_number` is enabled and otherwise is a lower bound such as `">3"`.
- A zero limit returns only the count, or `null` when association counting is disabled.
- A singular polymorphic association also includes its human model name.

For example, limit the returned tags to two and request an exact association count:

{% highlight ruby -%}
config.columns[:tags].associated_limit = 2
config.columns[:tags].associated_number = true
config.mcp.expose :list, columns: %i[id subject tags]
{%- endhighlight %}

When the record has three tags, the output makes the truncation explicit:

{% highlight json -%}
{
  "id": 42,
  "subject": "Unable to sign in",
  "tags": {
    "first_records": [
      {"id": 2, "label": "Important"},
      {"id": 3, "label": "Open"}
    ],
    "count": 3
  }
}
{%- endhighlight %}

If the complete collection fits within the limit, the key is `records` instead:

{% highlight json -%}
{
  "tags": {
    "records": [
      {"id": 2, "label": "Important"},
      {"id": 3, "label": "Open"}
    ],
    "count": 2
  }
}
{%- endhighlight %}

With `associated_number = false`, MCP avoids an exact count. A truncated collection then reports a lower bound such as `"count": ">2"`. Setting `associated_limit = 0` and `associated_number = true` returns only the count:

{% highlight json -%}
{
  "tags": 37
}
{%- endhighlight %}

Finally, a singular polymorphic association includes `model` so clients can distinguish records with the same identifier:

{% highlight json -%}
{
  "subject": {
    "id": 7,
    "label": "Router 7",
    "model": "Router"
  }
}
{%- endhighlight %}

## Customize presentation

For presentation-independent computed data, add a presenter module and define a `<column>_column` method:

{% highlight ruby -%}
module TicketMCPPresentation
  def summary_column(record, _column)
    record.summary.to_s.strip
  end
end

config.mcp.expose :show,
                  columns: %i[id summary],
                  presenter_modules: TicketMCPPresentation
{%- endhighlight %}

A custom presenter class can replace the default presenter for more extensive serialization changes:

{% highlight ruby -%}
class TicketMCPPresenter < ActiveScaffold::MCP::Presenter
  # Override presentable_column?, record, or presentation helpers.
end

config.mcp.expose :show, presenter: TicketMCPPresenter
{%- endhighlight %}

Subclassing `ActiveScaffold::MCP::Presenter` is recommended when only part of the standard serialization behavior needs to change. A replacement that does not subclass it must accept the tool in `initialize`, implement `presentable_column?`, and implement `record(record, columns, association_counts)`. The default presenter exposes its tool and delegates `active_scaffold_config`, `params`, and `current_user` for presentation that depends on the current invocation.

Use `presenter_modules` for result presentation and `modules` for query or authorization behavior. Each generated action receives its own anonymous presenter subclass when presenter modules are configured.

See [Authentication, Authorization, and Tool Discovery](/doc/active-scaffold-mcp-authentication/) for the checks applied before and during read-tool execution.
