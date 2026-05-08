---
title: "API: FilterOption"
category: "API Reference"
---

Filter's options are added to the filter calling `add` in the filter object. Add receives the option's name, and a hash of any other attributes, such as `description`, `conditions` or any `ActionLink` attribute, such as `label` or `security_method`. The option's label defaults to the option's name as symbol.

If the filter's option has a security method, it won't be rendered in the filter if the security method returns false or nil, and the security method will be checked too if the request's parameters have that option, if the security method returns false or nil, the default option of the filter will be used.

## conditions

The conditions added to the query when this filter's option is selected.

The conditions may be defined with a hash, which is passed to `where` method of `ActiveRecord`:

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :active, label: 'Active', conditions: {active: true}
{%- endhighlight %}

Also, they can be defined with a lambda or proc, which receives an `ActiveRecord::Relation` object, and must return another one, which allows to use scopes and build more complex queries:

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :active, label: 'Active', conditions: lambda { |query| query.active }
{%- endhighlight %}

From the lambda, it can call controller's methods (e.g. `current_user` in the next example) or access the params:

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :active, label: 'Active',
             conditions: lambda { |query| query.merge(current_user.send(params["parent_scaffold"] == 'users' ? :self_and_descendants : :self_and_children)) }
{%- endhighlight %}


## description

The tooltip of the option, added as title attribute to the action link, when the filter's type is `:links`, or the title attribute in the option tag, when the filter's type is `:select`. It can be a string, or a symbol to be translated with `as_` (under `active_scaffold` scope).

{% highlight ruby -%}
conf.list.filters.add :filter do |filter|
  filter.add :all, description: 'all users'
  filter.add :active, description: :active_users
end
{%- endhighlight %}

## filter_name

The filter's name, set when added to the filter, and can't be changed.

## name
The option's name is set when added to the filter, and can't be changed. It's used as the parameter value.
