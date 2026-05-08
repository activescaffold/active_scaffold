---
title: "API: Subform"
category: "API Reference"
---

The Subform action is unique because it is only used by _other_ controllers. When some other controller is displaying a Create or Update form with an association to the model configured on this controller, the other controller will try and use the subform settings from this controller to display its form. The controller which displays an associated model as subform must include this action too, otherwise the "create another" button won't work because edit_associated action won't be defined.

So, ensure you have :subform action in associated model actions hash.

If this configuration isn't being used, you may need to override `active_scaffold_controller_for` and define your own ActiveRecord => ActionController lookup rules. See [API: Core](/doc/api-core/) for more information.

## columns <small><em>local</em></small>

Lets you define the set of columns used by _other_ controllers on their Create and Update forms. When the other controllers need to display a summary sub-form for the record scaffolded on this model, they will attempt to use this set of columns.

Example:

{% highlight ruby -%}
config.subform.columns.exclude :company_type
{%- endhighlight %}

## layout <small><em>global local v2.3</em></small>

Lets you define the layout used by _other_ controllers on their Create and Update forms. When the other controllers need to display a summary sub-form for the record scaffolded on this model, they will attempt to render the partial `_#{layout}_subform.html.erb`. Possible values are `:horizontal` and `:vertical`. 
