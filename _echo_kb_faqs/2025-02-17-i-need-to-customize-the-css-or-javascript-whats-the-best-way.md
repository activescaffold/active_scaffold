---
title: "I need to customize the CSS (or JavaScript). What’s the best way?"
date: "2025-02-17 14:38:07.000000000 +01:00"
---

Don’t edit the ActiveScaffold files in public/! These files are automatically copied from vendor/plugins/active\_scaffold every time the server starts, to make sure you’re using the latest code. Instead, treat them the same way you’d treat the rest of the ActiveScaffold code – override them somewhere else, or use [Piston](http://piston.rubyforge.org/) and edit the original file in vendor/plugins/active\_scaffold.

For example, if you want to customize the CSS, create public/stylesheets/active\_scaffold\_overrides.css and include that file in your layout by placing `<%= stylesheet_link_tag 'active_scaffold_overrides' %>` **after** the `<%= active_scaffold_includes %>`.
