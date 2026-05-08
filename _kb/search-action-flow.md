---
title: "Search Action Flow"
category: "Action Flows"
---

# Action 'show_search'

By default, ActiveScaffold has the action module `:search`, but it can be changed to `:field_search`, using `conf.actions.swap :search, :field_search`. Both modules use the action `show_search` to open the form.

The search forms submit the data to the `index` action.

## Using 'search' module

These methods are called in the following order:

![Show_search action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/show_search.drawio.svg)

1. `search_authorized_filter` called as before_action
   1. `search_authorized?` (or the method defined in conf.search.link.security_method if it's changed) is called to check the permission. If this method returns false, `search_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `show_search`
   1. `respond_to_action`, which will call the corresponding response method for show_search action and the requested format.

Then it will render these views:
* search.html.erb (only for HTML request)
  * _search.html.erb

### Search Conditions Generation

There will be only a search string, and the query looks for it on every column in `config.search.columns`, using `column.search_sql` to build the conditions, joining all the comparisons with `OR`. `Search_sql` may be an array of column names or SQL code, e.g. using functions. The comparison will be made with `LIKE` for text columns and `=` for other columns, and depending on the value of `config.search.text_search` will use wrap the text:

* with `%` if it's `:full`, to match the text anywhere in the columns
* appending `%` if it's `:start`, to match the text at the beginning
* prepending `%` if it's `:end`, to match the text at the end
* without adding any `%`, if it's any other value, to match the exact text

And depending on the value of `config.search.split_terms`, it will look for the whole text, or will split the text using the value of `split_terms` into tokens and look for each token, joining everything with `AND`, so it requires to find every token, but each token may be found in different columns.

## Using 'field_search' module

These methods are called in the following order:

![Show_search action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/show_search_field_search.drawio.svg)

1. `search_authorized_filter` called as before_action
   1. `search_authorized?` (or the method defined in conf.field_search.link.security_method if it's changed) is called to check the permission. If this method returns false, `search_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `show_search`
   1. `respond_to_action`, which will call the corresponding response method for show_search action and the requested format.

Then it will render these views:
* field_search.html.erb (only for HTML request)
  * _field_search.html.erb
    * _field_search_columns.html.erb

Some of the columns defined in `config.field_search.columns` may be rendered in a subgroup which is collapsible and hidden by default, adding them to `config.field_search.optional_columns` too. When the form is open with a search active, they will be in the default group instead of the optional subgroup. The method `visibles_and_hiddens` can be overrided in a helper module to change the columns which are hidden, e.g. depending on params used to load the list.

If subgroups of columns are added, a subsection will be added, and rendered calling `render_subsection` helper method, which will add the subsection header and render the columns with `_field_search_columns` partial again.

### Search Conditions Generation

There will be different search params for each column, and each column may generate SQL condition in a different way. For each column in `conf.field_search.columns` will call the class method `condition_for_column`, which may use the following class methods:

1. `condition_for_<column_name>_column` if exists, allowing to override how the conditions for a column are generated
2. `condition_for_<search_ui>_type` if exists, with `search_ui` being the `search_ui` of the column, or the column's type if no search_ui was defined.
3. `column.search_sql` if it's a Proc
4. `condition_for_search_ui`

If the first method exists, it will be called and the value returned as SQL condition, otherwise, the value of one of the other 3 methods is expected to be a string used as SQL comparison (like the one used in `where` rails method when using an array), and one or more values, and the SQL string is used as a template used to interpolate, replacing `%<search_sql>s` or `%{search_sql}` with each item in `column.search_sql`, and joining all the conditions with `OR`.

For example, an association column :user with these settings:

{% highlight ruby -%}
conf.columns[:user].search_ui = :string
conf.columns[:user].search_sql = ['users.name', 'users.email']
{%- endhighlight %}

To generate conditions, with a search param `{user: {from: 'John', opt: '?%'}}`, `condition_for_search_ui` would be called, and would return `['%<search_sql>s LIKE ?', 'John%']`. Then, `condition_for_column` would return `['users.name LIKE ? OR users.email LIKE ?', 'John%', 'John%']`.

When using field_search, the items in `search_sql` array can be a hash too, to use a subquery for the condition, with the following structure:

* `subquery` key, required, with an array:
  * the first element in the array must be the model or ActiveRecord relation used for the subquery. If the relation doesn't select one column for the subquery, the primary key will be used.
  * the next elements are column names or SQL code, like normal items in `search_sql`, used for the conditions in the subquery
* `field` key, optional, the column name to match with the subquery result
* `conditions` key, optional, an array with extra conditions, like the parameters for `where` method from ActiveRecord.

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

## Using both modules

Field_search module can be added without using swap, with `conf.actions << :field_search`. ActiveScaffold don't support having 2 action links for the same action with the same parameters, so the action link for field_search should use the parameter `kind` with the value `:field_search`:

`conf.field_search.link.parameters = {kind: :field_search}`

Then show_search will render the view or partial for search module, and show_search with kind=field_search will render the view or partial for field_search module.

## Accessing to the search params

When index action is called, a before_action `store_search_params_into_session` will read the params in `:search` key, and delete them. If `active_scaffold_config.store_user_settings` is enabled, search params are saved in the session, in `active_scaffold_session_storage['search']`, otherwise search params are saved in `@search_params`. Anyway, search params are accessible with the method `search_params`, which can be used in controller, views and helpers. To access the search params for `field_search` only, in case of using both modules, `field_search_params` can be used, which will return `search_params` if it's a Hash, or an empty Hash.

The index action will add conditions to the list query from the search params with the `do_search` method, which is called with before_action too.