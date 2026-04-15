---
title: Adding custom actions
date: "2025-02-17 14:47:22.000000000 +01:00"
permalink: "/wiki-2/adding-custom-actions/"
---

When you add custom actions to a controller which uses ActiveScaffold, probably you will want to keep look and feel. Also, you have to follow some conventions so your action behaves as default actions, and ActiveScaffold provides some methods to DRY your code. Remember defining routes for your custom actions in config/routes.rb, e.g.:

```
resources :users do
  # AS default routes  
  as_routes
  # custom action routes
  put :deactivate, :on => :member
  put :archive, :on => :member
  put :reset_password, :on => :member
end
```
