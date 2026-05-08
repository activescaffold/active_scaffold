---
title: "List Action Flow"
category: "Action Flows"
---

# Action 'index'
These methods are called in the following order:

1. `list_authorized_filter` called as before_action
   1. `list_authorized?` is called to check the permission. If this method returns false, `list_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `index`
   * `row` if request is XHR, and params[:id] is present and it isn't an array, so it's just refreshing a row.
      1. `get_row`
         1. `set_includes_for_columns` which setup `active_scaffold_references` (used with `includes` and `references` methods when building the query) and `active_scaffold_preload` (used with `preload` method when building the query), based on the includes of the list columns, depending if column is used in the sorting (so it must be added to join in the query, so will be used in includes and references) or can be loaded in a separate query (so will be used in preload).
         2. `beginning_of_chain`, used as param for the next method to load the record.
         3. `find_if_allowed` to load the record to be edited into @record instance variable, checking :read permission.
      2. `respond_to_action`, which will call the corresponding response method for row action and the requested format.
   * `list` otherwise.
      1. `do_list` which sets @records with the records for the current page and @page with the page object generated with `Paginator` class.
         1. `current_page`
            1. `set_includes_for_columns` which setup `active_scaffold_references` (used with `includes` and `references` methods when building the query) and `active_scaffold_preload` (used with `preload` method when building the query), based on the includes of the list columns, depending if column is used in the sorting (so it must be added to join in the query, so will be used in includes and references) or can be loaded in a separate query (so will be used in preload).
            2. `find_page_options` which generates the options to pass to `find_page` method (`:sorting`, `:per_page` and `:page`, and `:select` if `auto_select_columns` is enabled in list action).
            3. `find_page`
               1. `finder_options` to return a hash with options used to call methods in the relation object when building the query, the key matching the method name (`:reorder`, `:joins`, `:left_joins`, `:preload`, `:includes`, `:references`, `:select`) and `:conditions` used with `where` method.
                  1. `custom_finder_options` which must return a hash to merge into the result returned by `finder_options`.
               2. `beginning_of_chain`, used as the relation object to build the query.
               3. `count_items` to run a COUNT query to count the total items when pagination is used, and it isn't set as :infinite, and calculate the number of pages.
               4. `append_to_query` to build the query with the options hash returned by `finder_options`
         2. `cache_column_counts`, receive the records set by `do_list`, and set @counts, which is a hash with column names as keys, and counts for each column as values. It uses a query to get the counts on all listed records for an association column, using group, instead of sending a count query for each record, when the column is a collection association and it has no includes defined (`includes = nil`) and it's set to display the number of associated records (`associated_number = true`, enabled by default). It's useful for associations which have many associated record, and want to display the number without displaying any other info for associated records (`associated_limit = 0`), so there is no need to load any associated record, just the count.
            1. `columns_to_cache_counts` which return the columns to cache counts for.
            2. `count_query_for_column` to return the query to call `count` on it (or `mongoid_count_for_column` if the model uses Mongoid instead of ActiveRecord, returning the count).
      2. `respond_to_action`, which will call the corresponding response method for list action and the requested format.

These methods can be overrided:
* `do_list` can be overrided, for example to change some values or params before calling super, to affect the query generation, or load some more data into instance variables which may be used later by helpers.
* `beginning_of_chain` can be overrided to add conditions loading the record or records, supporting scopes usage.
* `conditions_for_collection` can be overrided to add conditions loading the records, only when `list` is used (not refreshing a row), but it don't support scopes usage, it must return hash or array to be used with `where` method.
* `set_includes_for_columns` may be overrided to alter what associations are loaded with joins or separate queries, or add more associations to `active_scaffold_references`, `active_scaffold_preload` or `active_scaffold_outer_joins`.
* `custom_finder_options` may be overrided to add return other keys to call methods of ActiveRecord::Relation when building the query, e.g. `:having`, `:group`, `:order` (to add more clauses to `order by`), `:limit`, `:offset`, `:lock`, `:readonly`, `:from`. The same keys which return `finder_options` can be used too, to override the values generated by ActiveScaffold.
* `cache_column_counts` may be overrided to add counts for more columns, e.g. if they don't have associated_limit 0 but includes is cleared.
* `columns_to_cache_counts` may be overrided to return other columns to cache counts for.
* `count_query_for_column` may be overrided to change how count query is built, e.g. adding some conditions to the query to count only records matching some conditions.
{% highlight ruby -%}
def count_query_for_column(column, records)
  if column == :alerts
    super.where(cleared: false) # count only active alerts
  else
    super
  end
end
{%- endhighlight %}

When `row` is used, the action will render these views:
* row.js.erb
  * _list_record.html.erb, with local variable `record`
  * _update_calculations.js.erb
    * _list_calculations.html.erb

When `list` is used, the action will render these views:
* list.html.erb (only on HTML request, or loading embedded scaffold)
  * _list_with_header.html.erb
    * _list_header.html.erb, which renders the list title and the collection action links (using `display_action_links` helper)
    * active_scaffold_config.list.search_partial, which may be _search.html.erb or _field_search.html.erb, if `always_show_search` is enabled in list config. See [Search action flow](/doc/search-action-flow/) to other views used by these partials. 
    * _create_form_on_list.html.erb if always_show_create is enabled in list config, and create action is authorized. It will render _base_form partial, as _create_form partial does, but defaults to render without cancel button. See [Create action flow](/doc/create-action-flow/) for other partials used to render the form.
    * _list.html.erb to render the table with header and rows.
      * _messages.html.erb to render flash messages and internal error message, if `messages_above_header` is enabled in list config.
      * _list_column_headings.html.erb to render the `th` tags for the list header, with the local variable `columns`.
      * _list_messages.html.erb to render the tbody with other messages, filtered or empty list messages. It will render internal error and flash messages unless `messages_above_header` is enabled in list config.
      * _list_record.html.erb with the collection @page.items, if the page is not empty, with the locals `columns` and `action_links` with the member action links. It renders the `tr` rows in the `tbody` tag with class records.
      * _list_calculations.html.erb if any column has calculation setting, with the local variable `columns`.
      * _list_pagination.html.erb to render the list footer, with the records count unless pagination is set to `:infinite` in list config,  and the page links.
        * _list_pagination_links.html.erb, with the local variable `current_page`, if the pagination is enabled in list config and pagination is `:infinite` or has more than one page.

These partials can be overrided to change how list is rendered, and list_record partial supports calling `render :super` with some local variables to change some defaults:

* `columns` to use other columns to render, build the object with `active_scaffold_config.build_action_columns :list, [list of columns]`.
* `row_id` with the ID attribute for the tr tag, instead of default ID generated with `element_row_id` helper, for action `:list`.
* `tr_class` with the class attribute for the tr tag, which defaults to `even-record` on even rows, and the result of `list_row_class` helper.
* `action_links` to change the links rendered in the list, e.g. filtering some links out.
* `data_refresh` with the value of the `data-refresh` attribute for the tr tag, which defaults to `record.to_param`.