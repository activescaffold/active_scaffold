---
title: "ActiveScaffold Actions Flow"
category: "Action Flows"
---

ActiveScaffold actions have a common flow:

* `before_action <action>_authorized_filter`, which calls `link.security_method` (usually `<action>_authorized?`) and raise `ActiveScaffold::ActionNotAllowed` if it returns false.
* the action method usually calls `do_<action>`, which process the action, and `respond_to_action(:<action>)`, which will call the corresponding response method for the requested format, as explained in [Custom respond_to](/doc/custom-respond_to/)

When the action receives ID param, such as edit, update, delete or show, they load the record using `find_if_allowed` with the corresponding crud type (:create, :read, :update, :delete) to check the permissions. This method uses `beginning_of_chain` to build the query to load the record by id, which adds conditions to the query when the request has parameters for nested scaffold, so `beginning_of_chain` can be overrided to change the query used in list and any other action loading a record, it must return a ActiveRecord relation object.

That's the common flow, but some other methods are called from `do_<action>` in some actions:

* [Create action flow](/doc/create-action-flow/)
* [Update action flow](/doc/update-action-flow/)
* [Update_column action flow](/doc/update-column-action-flow/)
* [Render_field action flow](/doc/render-field-action-flow/) (refresh columns in forms)
* [Edit_associated action flow](/doc/edit-associated-action-flow/) (add row to subform)
* [Render_field action flow adding a tab](/doc/render-field-action-flow-adding-a-tab/) (add tab in tabbed subgroup)
* [Show action flow](/doc/show-action-flow/)
* [Destroy action flow](/doc/destroy-action-flow/)
* [Search action flow](/doc/search-action-flow/)
* [List action flow](/doc/list-action-flow/)