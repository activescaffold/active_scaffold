---
title: ActiveScaffold Actions Flow
date: "2025-02-17 13:51:18.000000000 +01:00"
permalink: "/wiki-2/activescaffold-actions-flow/"
---

ActiveScaffold actions have a common flow:

-   before\_action `<action>_authorized_filter`, which calls link.security\_method (usually `<action>_authorized?`) and raise ActiveScaffold::ActionNotAllowed if returns false.
-   the action method usually calls `do_<action>`, which process the action, and `respond_to_action(:<action>)`, which will call the corresponding response method for the requested format, as explained in [Custom respond\_to](https://github.com/activescaffold/active_scaffold/wiki/Custom-respond_to)

When the action receives ID param, such as edit, update, delete or show, they load the record using `find_if_allowed` with the corresponding crud type (:create, :read, :update, :delete) to check the permissions. This method uses `beginning_of_chain` to build the query to load the record by id, which adds conditions to the query when the request has parameters for nested scaffold, so `beginning_of_chain` can be overrided to change the query used in list and any other action loading a record, it must return a ActiveRecord relation object.

That's the common flow, but some other methods are called from `do_<action>` in some actions:

-   [Create action flow](https://github.com/activescaffold/active_scaffold/wiki/Create-Action-Flow)
-   [Update action flow](https://github.com/activescaffold/active_scaffold/wiki/Update-Action-Flow)
-   [Update\_column action flow](https://github.com/activescaffold/active_scaffold/wiki/Update-Column-Action-Flow)
-   [Render\_field action flow](https://github.com/activescaffold/active_scaffold/wiki/Render-Field-Action-Flow) (refresh columns in forms)
-   [Edit\_associated action flow](https://github.com/activescaffold/active_scaffold/wiki/Edit-Associated-Action-Flow) (add row to subform)
-   [Render\_field action flow adding a tab](https://github.com/activescaffold/active_scaffold/wiki/Render-Field-Action-Flow-Adding-a-Tab) (add tab in tabbed subgroup)
-   [Show action flow](https://github.com/activescaffold/active_scaffold/wiki/Show-Action-Flow)
-   [Destroy action flow](https://github.com/activescaffold/active_scaffold/wiki/Destroy-Action-Flow)
-   [Search action flow](https://github.com/activescaffold/active_scaffold/wiki/Search-Action-Flow)
-   [List action flow](https://github.com/activescaffold/active_scaffold/wiki/List-Action-Flow)
