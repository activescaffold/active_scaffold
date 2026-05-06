---
title: Action Links Order
date: "2025-02-17 13:34:46.000000000 +01:00"
permalink: "/wiki-2/action-links-order/"
---

The order of action links is defined by order in action\_links array. The follow line in `display_action_links` helper called from `list_record` and `list_header` partials iterates over action\_links adding them to the page:

`action_links.each(...)`

Due to CSS, they are displayed in reverse order at list header and in right order for each record.

Custom action links (action links created in your controller with `config.action_links.add` or `config.nested.add_link`) are added to action\_links array first, and default action links (links from actions like :create, :search, :update and so on) are added last. The order of action links is:

-   At list header, default action links in reverse order and then custom action links in reverse order
-   At each record, custom action links and then default action links.

Action links are sorted by weight (0 by default), so you can change order setting weights for some action links, negative ones for action links which should be displayed first, positive ones to move some action link to the end. Remember that collection action links are displayed on reverse order. To change the default order for all controllers use set\_defaults in ApplicationController:

```
ActiveScaffold.set_defaults do |config|
  config.delete.link.weight = 100
end
```
