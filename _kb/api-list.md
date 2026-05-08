---
title: "API: List"
category: "API Reference"
---

## always_show_create <small><em>global local</em></small>

Always show create is an option that will always show the create form while on the list view.  If the create action is disabled this option has no affect.  It also has no affect on nested views.  This option does not display the Create new action link, or the cancel/close option on the create view because the create section is always showing.

Examples:

{% highlight ruby -%}
config.list.always_show_create = true
{%- endhighlight %}

## always_show_search <small><em>global local</em></small>

The always show search option always show the search form while on the list view.  This option has no effect if the search and field_search action is excluded.  It will in turn display the corresponding search view, regular search or field search.  This option does not display the search action link, and removes the close option from the search container because the search is always showing.

It can be set to :search or :field_search, so that kind of search is always displayed when both searches, search and field_search, are enabled.

Examples:

{% highlight ruby -%}
config.list.always_show_search = true
{%- endhighlight %}

{% highlight ruby -%}
config.actions.swap :search, :field_search
config.actions << :search
config.list.always_show_search = :search
{%- endhighlight %}

## association_join_text <small><em>global local v2.4+</em></small>

Defines what string to use to join records from plural associations. Defaults to `", "`.

## auto_pagination <small><em>global local v3.4</em></small>

When enabled, first page is loaded in first request, then all pages are loaded and displayed by ajax automatically.

## auto_select_columns <small><em>global local v3.3</em></small>

Enable it to automatically select only columns included in list. It uses [API: Column]#select_columns for every included column, so virtual columns or columns with field overrides must set select_columns to work. Defaults to false.

## cache_column_counts <small><em>controller method</em></small>

It's called to preload the counts of collection association columns which has empty `includes`, `associated_number` is enabled, and don't use counter cache. It sets `@counts` instance variable with a hash, indexed by column name, with the result of grouped count query, so counts for an association is got with one SQL query for all records. See [Preload Column Counts](/doc/preload-column-counts/) for an explanation on how it works and how to change the column to count, e.g. adding some conditions to count some records only.

## calculate_etag <small><em>global local v3.4</em></small>

Enable ETag calculation (when conditional_get_support is enabled), it requires to load records for page, when is disabled query can be avoided when page is cached in browser.

## column_attributes <small><em>helper</em></small>

It returns a hash with attributes for the `<td>` tag of a column. It can be overrided, with the same name, or prefixed with the model name as column overrides, defining a per-model helper, e.g. `user_column_attributes` for User model. The `:class` key will be overrided with the result of column_class helper, so it must be used to define other html attributes than `class`.

{% highlight ruby -%}
def user_column_attributes(column, record)
  if column == :role && record.role
    {title: record.role.description}
  else
    {}
  end
end
{%- endhighlight %}

## column_class <small><em>helper</em></small>

It returns the default classes for `<td>` tag of a column. It can be overrided to add more classes for a record and a column:

{% highlight ruby -%}
  def column_class(column, column_value, record)
    classes = super
    if [:acc_balance, :balance].include? column.name
      if record.send(column.name) >= 0
        classes << 'debit '
      else
        classes << 'credit '
      end
    end
    classes
  end
{%- endhighlight %}

## columns <small><em>local</em></small>

The set of columns used for the List action.  By default, all but :id, foreign keys, updated/created_on/at columns are inherited from `config.columns`.  You can mandate which columns to inherit from `config.columns`, and also tell active scaffold which order to display the columns in:

{% highlight ruby -%}
config.list.columns = [:id, :name, :user_id, :created_on]
{%- endhighlight %}

If you want to change the attribute of a column, like the label, you must do in `config.columns`, which keeps column configuration, `config.list.columns` only store what columns display and the order.

{% highlight ruby -%}
config.columns[:created_on].label = "How old"
{%- endhighlight %}

Columns with plural associations will be render as a link to nested view.

Columns with singular associations will be render as a link to create when there is no associated record and create is authorized. When the column has an associated record will be linked to the edit view if record is authorized for update, or show view if it's authorized for read and not for update. If the action is excluded in the association's controller, column is not linked to that action too. You can control what actions are tried with [API: Column](/doc/api-column/)#actions_for_association_links.

If a link is set to a column using [API: Column](/doc/api-column/)#set_link, automatic linking will be ignored for it. You can supress automatic linking for a column using [API: Column](/doc/api-column/)#clear_link.

## conditions_for_collection <small><em>controller method</em></small>

If you want to add custom conditions to the find query used by List, then define this method. It may return conditions in string or array syntax. And as an instance method on the controller, it has access to params and session and all the standard good stuff.

Example:

{% highlight ruby -%}
def conditions_for_collection
  ['user_type IN (?)', ['admin', 'sysop']]
end
{%- endhighlight %}

If you want to add custom conditions in some columns from associations, you can use conditions_for_collection and you must enable join with the association. You can set includes in the association column (although it's enabled by default) if it's included in list columns, or you can add the assocation to `active_scaffold_includes`, `active_scaffold_outer_joins`, or override `joins_for_collection` for a INNER JOIN.

In rails 4, if you use a string condition and you use includes, don't forget to add the association to `active_scaffold_references`.

{% highlight ruby -%}
def conditions_for_collection
  if params[:admin]
    # user has_and_belongs_to_many user_types
    self.active_scaffold_includes << :user_types
    self.active_scaffold_references << :user_types
    ['user_types.name IN (?)', ['admin', 'sysop']]
  end
end
{%- endhighlight %}

{% highlight ruby -%}
def conditions_for_collection
  if params[:admin]
    # we don't need user_types columns, only join to use in where clause
    self.active_scaffold_outer_joins << :user_types
    ['user_types.name IN (?)', ['admin', 'sysop']]
  end
end
{%- endhighlight %}

## count_includes <small><em>local</em></small>

Overrides default includes used for count sql query. Use to speed up query to count records when you need many includes to list records.

## custom_finder_options <small><em>controller method</em></small>

If you want to add custom options, e.g. grouping or sorting to the find(:all) used by List, then define this method. It may return hash with symbol keys, such as `:reorder`, `:group`, `:having`, etc. And as an instance method on the controller, it has access to params and session and all the standard good stuff.

Example:

{% highlight ruby -%}
def custom_finder_options
  {:reorder => "some_field = #{some_magic_value} DESC, another_field ASC NULLS LAST"}
end
{%- endhighlight %}

## empty_field_text <small><em>global local</em></small>

Defines what appears when a field is empty. This can be important for columns with links - without some empty field text the link would have no clickable area. Defaults to a single hyphen.

## filters <small><em>local</em></small>

Filters work like special action links to index action, adding conditions to the list. A filter support different options, and there is always one active option on each filter. Each filter has a unique name, and it's used as the parameter to send when selecting a filter option, using the filter option's name as the value.

Filter can be added with `conf.list.filters.add` or `conf.list.filters <<` which accepts a name, and a block to add the options.

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :all, label: 'List All Revs'
  filter.add :latest, label: 'List Latest Revs', conditions: {is_latest: 1}
end
{%- endhighlight %}

An existing filter can be get with `conf.list.filters[name]`, or deleted with `conf.list.filters.delete name`.

Filters can be rendered in different ways, and the default can be set with `default_type`:

{% highlight ruby -%}
  conf.list.filters.default_type = :select
{%- endhighlight %}

The default can be changed globally in `ActiveScaffold.defaults` too:

{% highlight ruby -%}
ActiveScaffold.defaults do |conf|
  conf.list.filters.default_type = :select
end
{%- endhighlight %}

## filter_human_message <small><em>global local</em></small>

Enable it to display a message with the selected filters.

## filtered_message <small><em>local</em></small>

You can set the message displayed when you do a search. Default value is `:filtered`. You can set a different message symbol to get translated with I18n, or set a text with won't be translated. Also, you can change text in your locale file.

## formats <small><em>local</em></small>

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for the list action you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.list.formats << :pdf
# or
config.list.formats = [:pdf]
{%- endhighlight %}

## hide_nested_column <small><em>local</em></small>

ActiveScaffold doesn't display parent column in nested scaffolds. Enable this property so parent column will be displayed when you open a nested scaffold.

## joins_for_collection <small><em>controller method</em></small>

You can override this method to add some joins to the list query. It must return an array of symbols, hashes of symbols (which must be associations and you will get a inner join) or join strings, the same arguments accepted by joins method from ActiveRecord.

{% highlight ruby -%}
def joins_for_collection
  [:user_types, 'LEFT JOIN customers ON customers.sales_rep_id = users.id']
end
{%- endhighlight %}

## label <small><em>local</em></small>

The label of the list. Appears in the table heading.

## list_row_attributes <small><em>helper method, v3.6+</em></small>

It can be overrided to change the attributes used in `<tr>` tag, or add more attributes. It defaults to add id attribute, data-refresh attribute, and class attribute with value "record #{tr_class}".

Example:

{% highlight ruby -%}
# the Helper for the LedgerController
module LedgerHelper
  def list_row_attributes(tr_class, tr_id, data_refresh)
    super.merge(...)
  end
end
{%- endhighlight %}

## list_row_class <small><em>helper method, v1.1+</em></small>

> Since version "3.2.1", this helper is defined per-model using the format "<model_name>_list_row_class", for example "user_list_row_class"

If you need to customize the CSS class of a `<tr>` or a `<td>` tag based on some attribute of the record, then you should define a method in your helper file named `list_row_class`. This method should return a CSS class. You can then use the custom CSS class, combined with the built-in classes of the columns, to add styles as desired.

Example:

{% highlight ruby -%}
# the Helper for the LedgerController
module LedgerHelper
  def list_row_class(record)
    record.transaction < 0 ? 'negative' : 'positive'
  end
end
{%- endhighlight %}

In your main.css (or other)
{% highlight css -%}
.active-scaffold tr.negative td.amount-column {
  background-color: red;
}
{%- endhighlight %}

## messages_above_header <small><em>global local</em></small>

Display messages above of columns header instead of below of it

{% highlight ruby -%}
config.list.messages_above_header = true
{%- endhighlight %}

## no_entries_message <small><em>local</em></small>

You can set the message displayed when no items can be found. Default value is `:no_entries`. You can set a different message symbol to get translated with I18n, or set a text with won't be translated. Also, you can change text in your locale file.

## page_links_inner_window <small><em>global local v2.3+</em></small>

How many page links around current page to show. Default is 2, so a list with 10 pages showing page 5 will show:

`Previous 1 .. 3 4 5 6 7 .. 10 Next`

It was named `page_links_window` until 3.2.5, when was renamed to `page_links_inner_window`

## page_links_outer_window <small><em>global local v3.2.5+</em></small>

How many page links around first and last page to show. Default is 0, so a list with 10 pages showing page 5 will show:

`Previous 1 .. 3 4 5 6 7 .. 10 Next`

## pagination <small><em>global local v2.3+</em></small>

What kind of pagination to use:

- `true`: The usual pagination
- `:infinite`: Treat the source as having an infinite number of pages (i.e. don't count the records; useful for large tables)
- `false`: Disable pagination

## per_page <small><em>global local</em></small>

How many records to show on each page. Default is 15.

## refresh_with_header <small><em>global local v3.3+</em></small>

Include list header when list is refreshed by JS (using refresh_list partial)

## reset_link <small><em>global local</em></small>

You can modify the link displayed to reset a search. It's a readonly property, but you can change link properties as explained in [API: Action Link](/doc/api-action-link/)

## reset_filter_link <small><em>global local</em></small>

You can modify the link displayed to reset the filters. It's a readonly property, but you can change link properties as explained in [API: Action Link](/doc/api-action-link/)

## show_search_reset <small><em>global local</em></small>

If you don't want ActiveScaffold displays a link to reset search, you can remove it disabling this property.

## show_filter_reset <small><em>global local</em></small>

If you don't want ActiveScaffold displays a link to reset the filters to the defaults, you can remove it disabling this property.

## sorting <small><em>local</em></small>

The default sorting for the page. When a user clicks on a column, they override this sorting. On the third click for a column, they reset the sorting back to this value. You can define the sorting either by a shortcut data structure like `{ :title => :desc }` or `[{ :title => :desc}, {:subtitle => :asc}]`, or you can use the methods in the examples below.

The sorting names here refer to columns in config.columns, and when ActiveScaffold tries to actually perform the sorting it will check the column configuration to see whether to use method sorting or sql sorting.

> columns that depend on method sorting must load and sort the entire table, and will not scale for large data sets. Try to sort on columns that use **sort_by :sql**.

Examples:

{% highlight ruby -%}
# default sorting: descending on the title column
config.list.sorting = { :title => :desc }

# default sorting: descending on title, then ascending on subtitle
config.list.sorting = [{ :title => :desc}, {:subtitle => :asc}]

# same thing, but without as much punctuation
config.list.sorting = { :title => :desc }
config.list.sorting.add :subtitle, :asc
{%- endhighlight %}

If you need more complicated sorting, try to use `custom_finder_options` controller method, e.g:

{% highlight ruby -%}
protected

  def custom_finder_options
    {:reorder => "some_field = #{some_magic_value} DESC, another_field ASC NULLS LAST"}
  end
{%- endhighlight %}

## wrap_tag <small><em>global local v3.2.8</em></small>

Set a tag name to get table cells content wrapped in that tag. It allows you for more css styling, for example a background color which doesn't fill all cell. It won't wrap inplace editable columns or columns with link, it's not needed to style them.

{% highlight ruby -%}
config.list.sorting = :span
{%- endhighlight %}

## Modifying how the data outputs

Would you like to format a number as currency?  Or, would you like to format a date a different way?  Would you like to combine two fields from your model in one column?  If you answer yes to any of these, you will want to read [Column Overrides (List)](/doc/column-overrides-list/).

## beginning_of_chain <small><em>controller method, v2.3+</em></small>

If you want to use named scopes to limit the resultset of find(:all) used by List, then override this method. It may return a scoped model. Defeault is active_scaffold_config.model. And as an instance method on the controller, it has access to params and session and all the standard good stuff.

Examples:

{% highlight ruby -%}
def beginning_of_chain
  super.vegetarian.older_than(20)
end
{%- endhighlight %}
