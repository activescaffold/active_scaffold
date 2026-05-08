---
title: "Show Action Flow"
category: "Action Flows"
---

# Action 'show'
These methods are called in the following order:

![Show action flow](https://github.com/activescaffold/active_scaffold/raw/refs/heads/master/diagrams/show.drawio.svg)

1. `show_authorized_filter` called as before_action
   1. `show_authorized?` (or the method defined in conf.show.link.security_method if it's changed) is called to check the permission. If this method returns false, `show_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `show`
   1. `do_show`
      1. `get_row` which uses `find_if_allowed` to load the record to be edited into @record instance variable, checking :read permission.
   2. `respond_to_action`, which will call the corresponding response method for show action and the requested format

`do_show` can be overrided, for example to change how record is loaded depending on the params of the request, or any other code to customize the action which should be executed before rendering the views.

Then it will render these views:
* show.html.erb (only for HTML request)
  * _show_actions.html.erb if `inline_links` is enabled in config.show, with locals `record` and `position` set to `:header`
  * _show.html.erb
    * _show_columns.html.erb
  * _show_actions.html.erb if `inline_links` is enabled in config.show, with locals `record` and `position` set to `:footer`

The `_show_actions` partial will display the action links with type `:member`, but will check if action link should be displayed with the helper `display_link_in_show?`, which receives link and position arguments, and default to display links at `:header` position only. It can be overrided to change which links are displayed and where, e.g. display only some links, or display them when position is `:footer` or any position, or display some links in header and some other links in footer. If action link is for show action in the same controller, without parameters (the default show link), or link is not authorized, it won't be displayed.

The `_show_columns` partial will display the defined columns in show action, it will be called recursively for the subgroup of columns. If the `show_ui` of an association column is set to `:horizontal` or `:vertical`, then will render `_show_association` partial, which will render `_show_association_horizontal` to display the association as a table, or `_show_association_vertical` to display them as subgroup rendering `_show_columns`. Both partials will get the columns to render from the helper `show_columns_for`, which defaults to the show.columns defined in the controller for the associated model.