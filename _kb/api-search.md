---
title: "API: Search"
category: "API Reference"
---

## action_group <small><em>global local</em></small>

Set this property so link is included in a group of links.

## columns <small><em>local</em></small>

The set of searchable columns. This list defaults to the textual database fields. Note that this does **not** include your associations. If you want to search on your associations you need to define the [API: Column](/doc/api-column/) and add them to this set.

Example:

{% highlight ruby -%}
class UsersController < ActionController::Base
  active_scaffold :users do |config|
    config.columns[:roles].search_sql = 'roles.name'
    config.search.columns << :roles
    config.columns[:user_type].search_ui = :select

    #to swap field_search and search
    config.actions.swap :search, :field_search
    config.field_search.link.parameters = {:kind => :field_search}
  end
end
{%- endhighlight %}

Example2 (PostgreSQL):

{% highlight ruby -%}
class UsersController < ActionController::Base
  active_scaffold :users do |config|
    config.columns[:roles].search_sql = 'roles.name||roles.company'
    config.search.columns << :roles
  end
end
{%- endhighlight %}

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for search you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.search.formats << :pdf
# or
config.search.formats = [:pdf]
{%- endhighlight %}

## full_text_search <small><em>global local until v2.2</em></small>

A flag for whether the search should do full-text searching in the database (LIKE %?%) or assume that search tokens will match the beginning (LIKE ?%). Default is :true.

> Since v2.3 is replaced with text_search

## link <small><em>global local</em></small>

The action link used to tie the Search box to the List table. See [API: Action Link](/doc/api-action-link/) for the options on this setting.

For further configurations, see API: Column for search_ui settings.

## live <small><em>global local v2.3+</em></small>

Automatically submits the search conditions to the server as you type. This has an upside and a downside: it provides more feedback to the user (they can see the search working), but it can be inefficient with server resources.

## reset_form <small><em>global local v3.7.3+</em></small>

When enabled, reset link will clear input fields in the search form, instead of refreshing the list without search and closing the form.

## split_terms <small><em>global local v2.4+</em></small>

A string used to split the search string in terms. Default is `' '`. Setting to nil disable splitting the search string.

## text_search <small><em>global local v2.3+</em></small>

A flag for how the search should do full-text searching in the database:

- :full (LIKE %%?%%)
- :start (LIKE ?%)
- :end (LIKE %?)
- false (LIKE ?)

Default is `:full`.
