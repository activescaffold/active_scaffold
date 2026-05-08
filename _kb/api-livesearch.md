---
title: "API: LiveSearch"
category: "API Reference"
---

The LiveSearch action is the same as Search except that it automatically submits the search conditions to the server as you type. This has an upside and a downside: it provides more feedback to the user (they can see the search working), but it can be inefficient with server resources.

> Since v2.4 LiveSearch is removed because is merged with Search, enabled with Search#live method.

## columns <small><em>local</em></small>

The set of searchable columns. This list defaults to the textual database fields.
See the section under Search for the specifics of how to include associated fields.
For LiveSearch the columns must be added to config.live_search

Example:
{% highlight ruby -%}
config.live_search.columns << :user
{%- endhighlight %}

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for live search you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.live_search.formats << :pdf
# or
config.live_search.formats = [:pdf]
{%- endhighlight %}

## full_text_search <small><em>global local until v2.2</em></small>

A flag for whether the search should do full-text searching in the database (LIKE %?%) or assume that search tokens will match the beginning (LIKE ?%). Default is :true.

## link <small><em>global local</em></small>

The action link used to tie the Search box to the List table. See [API: Action Link](/doc/api-action-link/) for the options on this setting.

## text_search <small><em>global local v2.3+</em></small>

A flag for how the search should do full-text searching in the database:

- :full (LIKE %%?%%)
- :start (LIKE ?%)
- :end (LIKE %?)
- false (LIKE ?)

Default is `:full`.