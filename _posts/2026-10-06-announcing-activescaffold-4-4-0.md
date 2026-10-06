---
title: "Announcing ActiveScaffold 4.4.0: Ready for UI Framework Adapters"
date: "2026-10-06 13:51:13.000000000 +02:00"
categories:
- Releases
---

**ActiveScaffold 4.4.0** is now available. This release introduces a flexible rendering API for integrating Bootstrap, Tailwind CSS, and other UI frameworks, adds local sorting for unpaginated lists, and improves search and query behavior—particularly on PostgreSQL—along with performance and Content Security Policy compatibility.

------------------------------------------------------------------------

## Build UI framework adapters without replacing every view

ActiveScaffold's new UI elements API makes the generated markup easier to adapt while preserving its behavior. Named elements cover lists, forms, searches, messages, pagination, action links, subforms, and show views.

An adapter can add or replace HTML attributes, change tags, or use a context-aware proc when classes depend on the rendered column, action, page, or authorization state:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :list_table,
                                      class: "table table-striped table-hover"

ActiveScaffold.set_element :list_title,
                           tag: :h1,
                           attributes: { class: "h3" }

ActiveScaffold.set_element :action_link do |context|
  classes = ["btn", "btn-sm"]
  classes << (context[:authorized] ? "btn-primary" : "btn-secondary disabled")
  [nil, { class: classes.join(" ") }]
end
{%- endhighlight %}

The API includes `set_element`, `set_element_tag`, `set_element_attributes`, `add_element_attributes`, and `set_element_proc`. Attributes supplied by ActiveScaffold are merged with adapter attributes so existing JavaScript hooks and application-specific classes remain intact.

Some framework components require more than a tag or class change. Focused helper extension points support those structural changes. For example, `list_table_html` can wrap a table in a responsive container, while pagination helpers can generate the list structure expected by Bootstrap. This combination of helpers and UI elements makes it possible to package a reusable framework adapter without maintaining copies of ActiveScaffold partials.

Read [Customizing UI Markup and Integrating CSS Frameworks](/doc/framework-ui/) for the complete API reference, available element list, dynamic context details, and examples for forms, action links, Bootstrap pagination, and responsive tables.

------------------------------------------------------------------------

## Local sorting for unpaginated lists

Lists without pagination can now be sorted in the browser. Clicking a sortable column heading reorders the current rows without making another request. ActiveScaffold derives appropriate sort values for common column types, while columns can opt out when their displayed value cannot be sorted locally.

------------------------------------------------------------------------

## Search and query improvements, especially on PostgreSQL

ActiveScaffold already supports PostgreSQL. Version 4.4 makes that existing support more robust, particularly for searches, filtering, sorting, and queries involving associations:

-   PostgreSQL `timestamp` and `timestamptz` values are accepted in URL conditions consistently with MySQL datetime columns.
-   Text-search operators can be configured per column, with `LIKE` used by default for collated PostgreSQL columns.
-   `search_sql` accepts symbols by default and delays table and column quoting until the query is generated. Strings remain available for cross-table columns and SQL functions.
-   Sorting now passes a hash to Active Record, leaving table and column quoting to Rails. Values containing SQL expressions may need `Arel.sql` when required by Rails.
-   Range parameters accept endless and beginless forms. For example, `/orders?created_at=2026-01-01..` filters records created on or after January 1, while `/orders?created_at=..2026-12-31` sets only the upper bound.
-   Applied filters and ignored filters—such as unknown or unauthorized filters—are tracked in `@filter_states`.
-   Queries involving association includes, multiple joins to the same table, SQL ordering expressions, and PostgreSQL `DISTINCT` handling are more reliable.

------------------------------------------------------------------------

## Performance, JavaScript, and security improvements

-   ActiveScaffold avoids a count query when every record fits on a non-full first page.
-   Out-of-range method-sorted pages return an empty collection.
-   Draggable lists now apply their hover class correctly while dragging.
-   `ActiveScaffold.js_config[:draggable_lists_options]` accepts additional jQuery UI Sortable options.
-   Highlight duration can be configured through `ActiveScaffold.js_config`.
-   `active_scaffold_javascript_tag` uses Rails' `nonce: true` support, allowing applications to enforce a nonce-based Content Security Policy without adding `unsafe-inline`.

------------------------------------------------------------------------

## Upgrade

Update your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4.0"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold
{%- endhighlight %}

ActiveScaffold 4.4 requires Ruby 3.2 or newer and Rails 7.2 or newer.

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
