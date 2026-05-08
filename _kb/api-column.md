---
title: "API: Column"
category: "API Reference"
---

## actions_for_association_links <small><em>global local v2.2</em></small>

A list of actions enabled for singular association columns. Removing an action from the list disables showing links to that action in lists. Possible values are :new, :edit, :show and :list. Defaults to `[:new, :edit, :show]`.

{% highlight ruby -%}
# Disable :new globally
ActiveScaffold::DataStructures::Column.actions_for_association_links.delete :new
# Only shows links to show in user column
config.columns[:user].actions_for_association_links = [:show]
{%- endhighlight %}

## allow_add_existing <small><em>local v2.4+</em></small>

Whether to enable add_existing for this column when is used as a subform

## associated_limit <small><em>global local v1.2</em></small>

The number of associated records to show. If there are more associated records, a ellipsis ("...") will be added and the number of associated records will be shown if associated_number is enabled. Set to nil to show all associated records. Defaults to 3.

## associated_number <small><em>global local v1.2</em></small>

A boolean for whether shows the number of associated records when all associated records aren't shown. Defaults to true.

## association.reverse

For association columns, lets you specify the reverse association name in case ActiveScaffold is unable to guess itself. For more information see the [API: Nested](/doc/api-nested/).

## attributes=

It allows to set any setting which is assigned with a setter (most of them) with a hash. For example:

{% highlight ruby -%}
conf.columns[:roles].attributes = {
  label: 'Select your roles',
  form_ui: [:select, label_method: :name_with_desc],
  options: {collapsible: true}
}
{%- endhighlight %}

## calculate

Defines a calculation on the column. Anything that ActiveRecord::Calculations::ClassMethods#calculate accepts will do. Only works on real columns. 

Examples: 

{% highlight ruby -%}
config.columns[:price].calculate = :sum
config.columns[:price].calculate = :average
{%- endhighlight %}

## clear_form_column_if

It accepts a proc that will be called when the column renders, such that we can dynamically hide or show the column. When the column is hidden, a hidden input will be rendered with empty value, to clear the value when saving. It's very similar to [hide_form_column_if](/doc/api-column/#hide_form_column_if), but it clears the column when the form is submitted and the column is hidden.

The column must be rendered when changing other column, using this column name in the `update_columns` setting of other column. The proc will be called with 3 arguments: record, column and scope.

The value can be a symbol too, then it will be treat as a method name of the model, called without arguments.

Finally, the value can be a boolean, in that case it should be changed per request, for example in `after_render_field`, to be useful.

{% highlight ruby -%}
config.columns[:my_column].hide_form_column_if = proc { |record, column, scope| record.vehicle_type == 'tractor' }
config.columns[:my_column].hide_form_column_if = :hide_tractor_fields? # or using a model method
{%- endhighlight %}

## clear_link <small><em>v1.1</em></small>

Clears out any existing link, and prevents ActiveScaffold from automatically adding a nesting link.

{% highlight ruby -%}
config.columns[:owned_by].clear_link
{%- endhighlight %}

## collapsed

Defines whether the column initializes in a collapsed state. Currently collapsing is only supported for association columns on the Create/Update forms.

## css_class

An extra css class to apply to this column. Currently used in List and Create/Update forms. In lists is added to TD tag, and in forms is added to DL tag, so you can set css for labels and fields. You can set a proc, which will get 2 arguments, column_value and record, but proc only will be used in List.

## default_value

The default value for a DB column, not virtual or association, can be changed in the ActiveScaffold config, overriding the default value defined in the DB. If no value is set, it will return the default value defined in the DB. This default value is used on the create form, new rows added to subforms, but not used for field search, as it doesn't make sense.

Also, when saving a form with empty value for the column, the DB default will be used, ignoring the default setting in the column. When `default_value` is not used, and DB has a default and column can't be null, ActiveScaffold won't allow to save empty string, it will set the default value. For example, a model with a column `action` and default value `New`:

{% highlight sql -%}
`action` VARCHAR(255) NOT NULL DEFAULT 'New'
{%- endhighlight %}

If the form submits an empty value for it, such as `{"record" => {"action" => ""}}`, ActiveScaffold will save `'New'`. If you want to default to `'New'` in the create form, or new rows in a subform, but allow user to save empty string, just don't set default in the DB, and set `default_value` in the ActiveScaffold config.

{% highlight sql -%}
`action` VARCHAR(255) NOT NULL DEFAULT ''
{%- endhighlight %}
{% highlight ruby -%}
conf.columns[:action].default_value = 'New'
{%- endhighlight %}

## default_value?

Returns true if the default value has been set in the ActiveScaffold config. If the column has a default value set in the DB, and no default value is set in the ActiveScaffold config, then it will return false although the column has default value.

## description

A short description or example text. Currently used in Update/Create. 

{% highlight ruby -%}
config.columns[:name].description = "Enter the users first and last name"
{%- endhighlight %}

If you don't set a text, it will use the key activerecord.description.model_name.column_name to search a description translation.

## disable_on_update_column

When the column has `:update_columns` set, it sends a request to refresh some fields, and the form is disabled while the request is running, if this option is enabled (by default), to avoid the user to change other fields such as the ones being refreshed or the changes would be lost when the fields are refreshed.

When this option is disabled, the form won't be disabled, which allows the user to change other fields without waiting, but it may be dangerous, unless the refreshed fields are read only, so use it at your own risk, preferably only when you know `:update_columns` will include readonly fields only.

## empty_field_text

Text to display when the column is empty, defaults nil, so `list.empty_field_text` is used

## form_ui <small><em>v1.1</em></small>

There are different [form_ui types](/doc/form_ui-types/) which may be used for a column. Depending on the column type, it may default to nil, rendering text field, or may default to one of these types. Each type support different options, which may be set in column.options, or can be provided next to the form_ui type since v3.7, in one assignment, and these options will be used instead of column's options, isolating the options for the form_ui from other column's options not related to the form_ui, which may pollute the html tag.

{% highlight ruby -%}
config.columns[:roles].form_ui = :select, {label_method: :human_label, draggable_lists: true}
{%- endhighlight %}

These options can be read with `form_ui_options` method if needed: `config.columns[:roles].form_ui_options`

Association columns render the whole subform when it's set to `nil` (default value), that lets you actually create/update associated records. The subform supports the option `:subform_columns`, which may be set in the column's options, or along the form_ui:

{% highlight ruby -%}
conf.columns[:risk_items].form_ui = nil, {subform_columns: [:line_item_number, :title,  :applicable_risk, :consequence]}
# or set in column's options, leaving default form_ui (so it can be shared with show_ui :horizontal or :vertical)
conf.columns[:risk_items].options[:subform_columns] = [:line_item_number, :title,  :applicable_risk, :consequence]
{%- endhighlight %}

## group_by

A string, symbol or array of strings or symbols with the SQL to group by. If it's a symbol, it should be a column name, if it's a string it can be a column name or SQL code, even using functions. It can be used to group by a column in an associated table, if defined in an association or a column with `search_joins`, or using SQL functions in the group clause.

{% highlight ruby -%}
config.columns[:samAccountName].group_by = ["left(samAccountName, 3)", :company]
config.columns[:tags].group_by = 'tag_memberships.created_at'
{%- endhighlight %}

## grouped_select

It's the SQL used in the select clause of a query for grouped search. It can be used to change the column used for the calculation in a grouped search. Also, it allows to use a virtual column in a grouped search.

{% highlight ruby -%}
config.columns[:count].grouped_select = 'table.id'
config.columns[:count].calculate = :count
{%- endhighlight %}

## hide_form_column_if

It accepts a proc that will be called when the column renders, such that we can dynamically hide or show the column. The column must be rendered when changing other column, using this column name in the update_columns setting of other column. The proc will be called with 3 arguments: record, column and scope.

The value can be a symbol too, then it will be treat as a method name of the model, called without arguments.

Finally, the value can be a boolean, in that case it should be changed per request, for example in `after_render_field`, to be useful.

{% highlight ruby -%}
config.columns[:my_column].hide_form_column_if = proc { |record, column, scope| record.vehicle_type == 'tractor' }
config.columns[:my_column].hide_form_column_if = :hide_tractor_fields? # or using a model method
{%- endhighlight %}

## includes

An array of associations for eager loading that are relevant for this column. For association columns, defaults to the association itself.  This is especially useful with virtual columns.  Consider the following example:

{% highlight ruby -%}
# last_transaction_date is a virtual column that references a joined field 

active_scaffold :users do | config |
  config.columns = [:name, :last_transaction_date, :status]  
  config.columns[:last_transaction_date] = "Last transaction date"
  config.columns[:last_transaction_date].includes = [:user_transactions]
  config.columns[:last_transaction_date].sort_by :sql => "user_transactions.created_at"
end
{%- endhighlight %}

## inplace_edit <small><em>v1.1</em></small>

Enable in_place_editor for this column (true, :ajax or false). Defaults to false. Validation errors are reported via page.alert.

<em>Since v2.3:</em>
- For columns with form_ui or form override, it will copy the fields from a hidden template in the column header instead of use the default InPlaceEditor.
- If inplace_edit is set to :ajax, an AJAX request will be made to get the field, that option is needed for in place editing with some form_ui, such as :record_select or :chosen.

{% highlight ruby -%}
active_scaffold :users do | config |
  config.columns[:title].inplace_edit = true # uses JS to show string field, or copy from UI from list header, same UI for each row, no AJAX request
  config.columns[:title].inplace_edit = :ajax # uses JS request to render UI in the server
end
{%- endhighlight %}

## inplace_edit_update <small><em>v3.3+</em></small>

Enable updating columns, row or table after updating the column with in_place_editor. Default is nil, which will update only the column,

Possible values are:
- `:columns` to update some columns, defined with `update_columns` attribute. If some column has update_columns, they will be updated too, avoiding circular dependencies.
- `:row` to update the row. It must be used if action_links can change after updating the column, for example due to permission checks.
- `:table` to update the table.

{% highlight ruby -%}
active_scaffold :users do | config |
  config.columns[:status].inplace_edit_update = :row # refreshes the whole row
  config.columns[:favorite].inplace_edit_update = :table # refreshes the whole table
  config.columns[:approve_reason].inplace_edit_update = :columns # refreshes the columns defined in next line
  config.columns[:approve_reason].update_columns = [:approved_at] # columns refreshed when inpace_edit_update is :columns
end
{%- endhighlight %}

## label

The displayable name.

{% highlight ruby -%}
config.columns[:created_at].label = "How Old"
{%- endhighlight %}

If you don't set the label, it will use the key activerecord.attributes.model_name.column_name to search a label translation.

Label can be set to a proc or lambda to support defining dynamic label in the controller for the form only, although label can be overrided with helpers, different helpers for different situations, see [Per Request Configuration](/doc/per-request-configuration/) for the different available helpers and examples.

{% highlight ruby -%}
config.columns[:password].label = Proc.new { |record, column, scope| record.requires_api_key? ? 'API Key' : 'Password' }
{%- endhighlight %}

When using a proc, the label will use the default value instead of proc when the record is not available, e.g. for horizontal subforms and list header.

## list_ui <small><em>v1.1</em></small>

There are different [list_ui types](/doc/list_ui-types/) which may be used for a column. Form_ui is used if list_ui is not specified and it exists such list_ui. Each type support different options, which may be set in column.options, or can be provided next to the list_ui type since v3.7, in one assignment, and these options will be used instead of column's options, isolating the options for the list_ui from other column's options not related to the list_ui, which may pollute the html tag.

Since v3.7, the options for the list_ui can be provided next to the list_ui type, in one assignment, and these options will be used instead of column's options, isolating the options for the list_ui from other column's options not related to the list_ui, which may pollute the html tag.

{% highlight ruby -%}
config.columns[:description].list_ui = :text, {truncate: 30}
{%- endhighlight %}

These options can be read with `list_ui_options` method if needed: `config.columns[:description].list_ui_options`
If no list_ui is defined, and form_ui is defined with options, list_ui_options will return the form_ui_options too, but if list_ui is defined without options, list_ui_options will never return form_ui_options.


## options

Html options for text input fields, and options for some form interfaces (see [form_ui](/doc/api-column/#form_ui) and [list_ui](/doc/api-column/#list_ui) methods).

`options[:format]` can be set for:
- date and time columns, and it will be used as the format argument of `I18n.localize` to format them.
- number columns, it can be `:i18n_number` (set by default), `:currency`, `:percentage` or `:size`. `:i18n_number` will use `number_with_delimiter`, other options will use `number_to_currency`, `number_to_percentage` or `number_to_human_size`. Options for these helpers can be set in `options[:i18n_options]`.

`options[:collapsible]` can be set to true to allow collapsing the column in Create/Update form, column is never collapsed initially.

`options[:tabbed_by]` can be set in columns, used when the column is in any subgroup of form action (create or update), and the subgroup is using `tabbed_by`, so it's only useful for collection associations.

`options[:subform_columns]` can be set to an array on association columns, and will be used when they are rendered as subform (`form_ui` is `nil`) instead of `subform.columns`, and in show action with show_ui `:horizontal` or `:vertical`, instead of `show.columns`.

{% highlight ruby -%}
conf.columns[:risk_items].options[:subform_columns] = [:line_item_number, :title,  :applicable_risk, :consequence]
{%- endhighlight %}

## placeholder <small><em>v3.3</em></small>

Specifies a placeholder for HTML `input` tag in create/update actions. Could replace or be used together with description.

If you don't set a text, it will use the key `activerecord.placeholder.model_name.column_name` to search a placeholder translation. Examples available on [appropriate pull request page](https://github.com/activescaffold/active_scaffold/pull/173) .

## required

A boolean for whether the column is required through already-existing validation. Currently used in Update/Create. Defaults to false, but if [validation reflection](http://github.com/redinger/validation_reflection) is available it defaults to true for columns with validates_presence_of. If it's true, the `required` attribute on HTML `input` tag will be set and modern browsers won't allow user to send form unless this column is filled.

## search_sql

The SQL string used when searching on this column. Defaults to the field name of the column for real columns, and `association_table.primary_key` for association columns. This SQL is the left side of a condition, which means that if you want to do something with multiple fields they have to be in a function. Since 3.2.13 you can set an array with multiple left sides, and conditions will be OR'ed.

{% highlight ruby -%}
# good. this will get turned into "WHERE name = ?"
config.columns[:name].search_sql = 'name'

# bad. this will get turned into "WHERE first_name OR last_name = ?", which is invalid syntax
config.columns[:name].search_sql = 'first_name OR last_name = ?'

# good. this will get turned into "WHERE CONCAT(first_name, ' ', last_name) = ?"
config.columns[:name].search_sql = "CONCAT(first_name, ' ', last_name)"
#good.  in PostgreSQL for multiple columns
config.columns[:name].search_sql = "first_name||last_name"

# good since 3.2.13. this will get turned into "WHERE first_name = ? OR last_name = ?"
config.columns[:name].search_sql = ["first_name", "last_name"]
{%- endhighlight %}

Note: After you define the search_sql you may need to add the column to the [API: Search](/doc/api-search/).

When using field_search, the items in `search_sql` array can be a hash too, to use a subquery for the condition, with the following structure:

- `subquery` key, required, with an array:
  - the first element in the array must be the model or ActiveRecord relation used for the subquery. If the relation doesn't select one column for the subquery, the primary key will be used.
  - the next elements are column names or SQL code, like normal items in `search_sql`, used for the conditions in the subquery
- `field` key, optional, the column name to match with the subquery result
- `conditions` key, optional, an array with extra conditions, like the parameters for `where` method from ActiveRecord.

For example, for a polymorphic association, in a Resume model:

{% highlight ruby -%}
    conf.columns[:resume_holder].search_sql = [
      {subquery: [User, 'first_name', 'last_name']},
      {subquery: [Candidate, 'first_name', 'last_name']}
    ]
{%- endhighlight %}

Then it would generate a condition when searching for 'John' like this:

{% highlight sql -%}
resume_holder_id IN (SELECT id FROM users WHERE first_name LIKE '%John%' OR last_name LIKE '%John%') AND resume_holder_type = 'User' OR
resume_holder_id IN (SELECT id FROM candidates WHERE first_name LIKE '%John%' OR last_name LIKE '%John%') AND resume_holder_type = 'Candidate'
{%- endhighlight %}

In that example, `field` key is not needed as the foreign key for the column is used, and `conditions` key is not needed because it's generated automatically to match the foreign type of the association. However, if using a virtual column, field will be needed, and conditions may be needed too, depending on the case:

{% highlight ruby -%}
    conf.columns[:parent].search_sql = [
      {subquery: [User, 'first_name', 'last_name'], field: :resume_holder_id, conditions: ['resume_holder_type = ?', 'User']},
      {subquery: [Candidate, 'first_name', 'last_name'], field: :resume_holder_id, conditions: ['resume_holder_type = ?', 'Candidate']}
    ]
{%- endhighlight %}

In the `subquery` key, scopes or where can be used, e.g. `User.where(disabled: false)`, or `select(:column)` to use it instead of `:id`.

## search_ui <small><em>v1.1</em></small>

There are different [search_ui types](/doc/search_ui-types/) which may be used for a column. Form_ui is used if search_ui is not specified and it exists such search_ui, otherwise the form_ui helper will be used, but using `search[field]` instead of `record[field]` in the name attribute. Each type support different options, which may be set in column.options, or can be provided next to the search_ui type since v3.7, in one assignment, and these options will be used instead of column's options, isolating the options for the search_ui from other column's options not related to the search_ui, which may pollute the html tag.

If no search_ui is defined, and form_ui is defined with options, search_ui_options will return the form_ui_options too, but if search_ui is defined without options, search_ui_options will never return form_ui_options.

{% highlight ruby -%}
config.columns[:roles].search_ui = :select, {label_method: :human_label}
{%- endhighlight %}

These options can be read with `search_ui_options` method if needed: `config.columns[:roles].search_ui_options`

For association columns, if search_ui and form_ui is not set, it defaults to `:select`, which works with the default search_sql, then it renders a select box to search for a specific object. Also, `:multi_select` or `:record_select` (if recordselect gem is available) may work with the default search_sql, `:multi_select` renders a collection of checkboxes to search for some specific objects. Other search_ui can be used to search in some field, setting search_sql.

## select_associated_columns <small><em>local v3.2.20</em></small>

**WARNING** Before v3.2.20 this method was named select_columns, added on v2.3

What columns load from association table when eager loading is disabled. It's only used when includes is nil.

{% highlight ruby -%}
# Turn off eager loading
config.columns[:association_column].includes = nil
# Select only the name
config.columns[:association_column].select_associated_columns = [:name]
{%- endhighlight %}

## select_columns <small><em>local v3.3</em></small>

What columns load from main table when [API: List]#auto_select_columns is enabled. By default is the own column for real columns and foreign key for belongs_to associations. Must be an array or nil.

{% highlight ruby -%}
# Turn off column selection
config.columns[:association_column].select_columns = nil
# Select two columns
config.columns[:association_column].select_columns = ['name, surname']
{%- endhighlight %}

## send_form_on_update_column <small><em>global local v2.4+</em></small>

Send all the form instead of single value when this column changes.
You can set `options[:send_form_selector]` to filter which fields are sent.
Also, you can set to `:row` and it will send only the row of the associated record instead of whole form, when column is in a subform.
When `:update_columns` contains a `Hash`, it will default to true, sending the whole form, as refreshing columns in other subforms won't work right it if the other subforms are not sent. 

## set_link

Sets the action link for this column. Currently used only in List. See [API: Action Link](/doc/api-action-link/) for options. This link will automatically get the id of the current row, but if you want to put any other dynamic values in the link you're better off just using a [Field Overrides](/doc/column-overrides-list/) .

## show_blank_record <small><em>global local v2.2</em></small>

Whether to show a blank record in subform or not. When is disabled, you must click in add new to get a blank row. Defaults to true.

{% highlight ruby -%}
# Turn off blank records in all subforms
ActiveScaffold::DataStructures::Column.show_blank_record = false
# And enable blank record to role column
config.columns[:role].show_blank_record = true
{%- endhighlight %}

## show_ui

There are different [show_ui types](/doc/show_ui-types/) which may be used for a column. List_ui is used if show_ui is not specified and it exists such show_ui, then will check if a show UI exists for the column's type, otherwise will use the same method used in list. Each show UI support different options, which may be set in column.options, or can be provided next to the show_ui type since v3.7, in one assignment, and these options will be used instead of column's options, isolating the options for the show_ui from other column's options not related to the search_ui, which may pollute the html tag.

{% highlight ruby -%}
config.columns[:description].show_ui = :text, {html_options: {class: 'description'}, wrapper_tag: :div}
{%- endhighlight %}

These options can be read with `show_ui_options` method if needed: `config.columns[:description].show_ui_options`
If no show_ui is defined, and list_ui is defined with options, show_ui_options will return the list_ui_options too, but if show_ui is defined without options, show_ui_options will never return list_ui_options.

## sort

A boolean for whether this column is sortable or not. Defaults to false for virtual columns.

## sort_by

Lets you define either the SQL used for sorting (defaults to the field name) or a string for method based sorting. 

{% highlight ruby -%}
# To sort by an SQL expression
columns[:name].sort_by :sql => 'concat(first_name, last_name)'

# To sort by multiple DB columns, more efficient than SQL expression becuase it can use indexes
# _(only since 3.2)_
columns[:name].sort_by :sql => ['first_name', 'last_name']

# to sort by a Ruby method (notice this is a method on the model you are scaffolding against):
columns[:name].sort_by :method => :full_name

# to sort by a proc, it gets no argument and execute in the model instance (with instance_exec)
columns[:name].sort_by :method => proc { full_name }
{%- endhighlight %}

Sort by method supports a symbol or String, but it must be a method name, and mustn't return nil or sort will fail. It used to accept a string with code to run with `eval`, but not anymore, it's unsafe and not needed.

Association columns don't support sorting by default, it must be defined on each column.

> Method-based sorting is slow and resource-intensive. The entire table must be loaded and sorted, which will not scale for large data sets. Try to use **sort_by :sql** as much as possible.

## subform_includes

An array of associations for pre-loading that are relevant for this column when used in a form. It isn't used unless the column is an association.

When the value is `true` (default value), if the column has a `form_ui` it will preload itself only, otherwise the column is rendered as a subform (unless there is a helper or partial override, but it isn't check at this step), it will get the associations to pre-load from subform columns in the associated controller.

It can be set to any other value (symbol, hash, array with symbols and hashes), then it will use that value with `preload` and won't check the associated controller. If it's set to false or nil, nothing will be pre-loaded.

{% highlight ruby -%}
config.columns[:monthly_task_costs].subform_includes = [:financial_month, rateable: {master_rate: :period}]
config.columns[:vendor].subform_includes = false
{%- endhighlight %}

## update_columns <small><em>v2.4+</em></small>

An array with the name of the columns to be updated in a form when this column changes. If some of these columns have update_columns, they will be updated too, avoiding circular dependencies.

{% highlight ruby -%}
conf.columns[:units].update_column = [:subtotal]
conf.columns[:unit_price].update_column = [:subtotal]
conf.columns[:subtotal].update_column = [:total] # when units or unit_price is changed, will change total too
conf.columns[:tax].update_column = :total # will be set as [:total]
{%- endhighlight %}

Also, the array may include hashes. The keys in the hash must be associations, and the values will be column names of the associated model, so it's possible to refresh columns in other subforms, without refreshing the whole subform. Nested hashes are supported, but they keys of a nested hash must be associations in the associated model.

{% highlight ruby -%}
conf.columns[:tax_exempt].update_column = [items: :tax] # update tax column in all items, as options will change
{%- endhighlight %}

An special value is supported in the keys, `:_root_`, to go up to the top of the form, so it's possible to have a column in a subform refreshing columns in the main form, or in other subforms that are not nested under the current subform.

{% highlight ruby -%}
# ItemsController
conf.columns[:total].update_column = [__root__: :total] # When the total of any item changes, update the total of the invoice
{%- endhighlight %}

Look at [Chaining Form Fields](/doc/chaining-form-fields/) for more detailed examples.

## weight <small><em>v1.2</em></small>

Add a weight to the column to override alphabetical sorting. Columns are sorted from the lowest weight to the highest one, and columns with the same weight are sorted alphabetically. You must assign weights before use `config.#{action}.columns`, whenever you call `config.#{action}.columns`, columns are sorted and copied from global config to action.