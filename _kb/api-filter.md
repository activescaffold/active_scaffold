---
title: "API: Filter"
category: "API Reference"
---

Filters work like special action links to index action, adding conditions to the list. A filter support different options, and there is always one active option on each filter. Each filter has a unique name, and it's used as the parameter to send when selecting a filter option, using the filter option's name as the value.

A filter will have a default option, which is the first added option but it can be changed.

## []

Returns an option from the filter by its name.

{% highlight ruby -%}
active_scaffold_config.list.filters[:filter][:latest]
{%- endhighlight %}

## add, aliased as <<

Adds a filter option, requires the filter option's name and optionally a hash with options for the filter option.

{% highlight ruby -%}
filter.add :latest, label: 'List Latest Revs', conditions: {is_latest: 1}
{%- endhighlight %}

## css_class

A string to add to the html of the filter, in the action link group if rendered as `:links` or in the select tag if rendered as `:select`.

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.css_class = 'user-filter'
{%- endhighlight %}

## default_option

The default option for the filter, which is the first option if none is specified. It can be changed providing the option's name.

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :all, label: 'List All Revs'
  filter.add :latest, label: 'List Latest Revs', conditions: {is_latest: 1}
  filter.default_option = :latest
end
{%- endhighlight %}

## delete

Deletes an option from the filter by its name.

## description

The tooltip of the filter, added as title attribute to the group of action links, with `:links` type, or as a select tag, with `:select` type. It can be a string, or a symbol to be translated with `as_` (under `active_scaffold` scope).

## label

The visible text for the filter, when is rendered as `:links`. It can be a string, or a symbol to be translated with `as_` (under `active_scaffold` scope). When the filter is rendered as `:select`, is used as the title attribute if the filter has no description. It defaults to use the filter's name.

## name

The filter's name is set when added to filters list, and can't be changed. It's used as the parameter name.

## security_method

Specifies a method on the controller that determines whether to disable this filter or not. Although a URL with the filter name in the parameters is sent, if this method disallows the filter, the parameter will be ignored. The method must return false (or nil) to disable the filter.

Values: a symbol naming the method (e.g. :logged_in?)

## type

Defines if the filter is rendered as a group of action links, with `:links` value, or as a select tag, with `:select` value. It defaults to `:links`, and default can be changed with `conf.list.filters.default_type`, per controller if used in the `active_scaffold` block of a controller, or globally if used in `ActiveScaffold.defaults`.

## weight

Used to alter the order in which filters are rendered. By default all filters have weight 0, and they are rendered as they are defined. The filter with lower weight value is rendered first.

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.weight = 1
{%- endhighlight %}
