---
title: "Those subforms are slick, but I want to turn them off. How can I simplify associations"
date: "2025-02-17 14:35:11.000000000 +01:00"
---

The `form_ui = :select` option lets you switch the form interface from the standard subform setup to a simple select setup. This configuration can be set per-column.

```
class UsersController < ApplicationController
  active_scaffold :users do |config|
    # users will no longer be able to create/edit Roles from the Users forms
    config.columns[:roles].form_ui = :select
  end
end
```
