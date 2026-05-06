---
title: "I need to customize the CSS (or JavaScript). What’s the best way?"
date: "2025-02-17 14:38:07.000000000 +01:00"
---

Don't edit ActiveScaffold's assets directly. ActiveScaffold is now a gem, and its assets are managed through the asset pipeline or Propshaft — editing gem files directly will cause your changes to be lost when the gem is updated.
Instead, override styles by creating app/assets/stylesheets/active_scaffold_overrides.css and adding your custom CSS there. Then, load it below `@use 'active_scaffold/core'` or `@use 'active_scaffold'`.

If you need to modify ActiveScaffold's behaviour beyond CSS — views, helpers, or JavaScript — the recommended approaches are:

- Override views by copying the relevant template from the gem into your own app/views directory. Rails' view resolution will pick up your copy first. In the directory for the controller you want to apply it, or active_scaffold_overrides to apply it to every controller.
- Override JavaScript by importing your own JS after ActiveScaffold's in your manifest or application.js.
- Create the same helper method in your helpers.