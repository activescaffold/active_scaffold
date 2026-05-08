---
title: "Template Overrides"
category: "Customization"
---

Every template in ActiveScaffold can be overridden with your own. Just find the template (anything in ActiveScaffolds' app/views/active_scaffold_overrides directory) you want to customize and copy it to your app/ folder. If you want to override the template for all controllers, copy it into the `app/views/active_scaffold_overrides/` directory. If you want to override the template for a specific controller, copy it into that controller's directory (e.g. `app/views/users/` for the UsersController).

## Wrapping Templates

If you want to wrap a template, you can create a file in one of the same two places with the same name, but somewhere in the template make a call to `render :super`. 

**Global Wrapping Example:** Copy from `<active_scaffold gem path>/app/views/active_scaffold_overrides/list.html.erb`  to `app/views/active_scaffold_overrides/list.html.erb`, then wrap the call to `render :super` in whatever content you want.

For an edit or update route you can access the object for the record in question using @record

{% highlight erb -%}
<!-- Whatever above -->

<%= render :super %>

<!-- Whatever below -->
{%- endhighlight %}

## Template Render Order

Rendering your template overrides will wrap in this order:

1. Wrapping Template `app/views/controller_name/template.html.erb`
1. ActiveScaffold Global Template Override `app/views/active_scaffold_overrides/template.html.erb`
1. ActiveScaffold Frontend `<active_scaffold gem path>/app/views/active_scaffold_overrides/template.html.erb`

