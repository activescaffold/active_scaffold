---
title: "Destroy Action Flow"
category: "Action Flows"
---

# Action 'destroy'
These methods are called in the following order:

![Destroy action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/destroy.drawio.svg)

1. `delete_authorized_filter` called as before_action
   1. `delete_authorized?` (or the method defined in conf.delete.link.security_method if it's changed) is called to check the permission. If this method returns false, `delete_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `destroy`
   1. `process_action_linnk_action`
      1. `get_row` which uses `find_if_allowed` to load the record to be edited into @record instance variable, checking :delete permission.
      1. `do_destroy`
   2. `respond_to_action`, which will call the corresponding response method for destroy action and the requested format.
      * For HTML request, calls `destroy_respond_to_html`
         * It will call `return_to_main` which redirects to `main_path_to_return`, which defaults to list.
      * For XHR request, calls `destroy_respond_to_js`
        * It will call `do_refresh_list` if record was deleted, and `refresh_list` is enabled in `config.delete`.
        * It will render `destroy.js.erb` view

`do_destroy` can be overrided to change how the record is destroyed, for example enabling a flag to hide the record instead of deleting it, `destroy_respond_to_html` or `destroy_respond_to_js` to change the response, or `destroy.js.erb` view to change or add some JS code to the response on XHR request.