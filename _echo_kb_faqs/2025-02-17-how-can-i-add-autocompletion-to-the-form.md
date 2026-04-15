---
title: "How can I add autocompletion to the form?"
date: "2025-02-17 14:35:22.000000000 +01:00"
---

You can use <a href="https://github.com/activescaffold/active_scaffold/wiki/Integration" class="internal present">RecordSelect integration</a>.
Also, you can use a <a href="https://github.com/activescaffold/active_scaffold/wiki/Form-Overrides" class="internal present">form override</a> to insert all the javascript necessary. Here’s an example from a user in the Google Group, using a partial:

```
<div style="height: 100px;">
  <label for="record_identity_type">Identity Type</label>
  <%= text_field_tag 'record[identity_type]', @record[:identity_type], :id => 'record_identity_type' %>
  <div class="auto_complete" id="identity_type_autocomplete_<%=@record[:id]%>" style="{height: 80px;}"></div>
  <%= javascript_tag("new Autocompleter.Local('record_identity_type',
    'identity_type_autocomplete_#{@record[:id]}',
    ['User', 'Group', 'AdminUser'],
    {fullSearch: true, frequency: 0, minChars: 1});") -%>
</div>
```
