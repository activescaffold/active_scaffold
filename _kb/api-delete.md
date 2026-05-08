---
title: "API: Delete"
category: "API Reference"
---

## action_group <small><em>global local</em></small>

Set this property so link is included in a group of links.

## formats 

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for the delete action you can do it here.  The format is then added to the default formats.

## link <small><em>global local</em></small>

The action link used to tie the Create action to the List table.  Most likely, you'll use this to change the label for your link.

{% highlight ruby -%}
config.create.link.label = "Add a new user"
{%- endhighlight %}

See [API: Action Link](/doc/api-action-link/) for additional parameters for this link.

## refresh_list <small><em>global local</em></small>

Enable this property to refresh list after successful deletion with AJAX.
