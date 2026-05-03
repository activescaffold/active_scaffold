---
layout: page
title: ActiveScaffoldDuplicate
date: 2025-02-18 12:00:25.000000000 +01:00
permalink: "/plugins/activescaffoldduplicate/"
parent: Plugins
hero_heading: Duplicate action for ActiveScaffold
hero_lead: An action to clone records
---

Adds an action to clone records, and support to clone rows in subforms. 

### Description

By default will only set attributes and belongs\_to associations. You must override initialize\_dup in your model or define a method to clone the record and set in conf.duplicate.method.

Duplicate rows in a subform, requires to set the \`:duplicate\` setting in the column's options, or \`form\_ui\_options\`.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_duplicate'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

Enable the advanced search functionality in your controller:

```
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.actions << :duplicate
  end
end
```
### Example Code

```
class OrdersController < ApplicationController
  active_scaffold do |conf|
    conf.duplicate.link.method = :get
    conf.duplicate.link.position = :after
    #conf.duplicate.link.page = true # for new page rendering
    conf.columns[:lines].form_ui = nil, {duplicate: true} # add a button to duplicate a line in the subform
  end
end
```
