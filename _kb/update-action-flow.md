---
title: "Update Action Flow"
category: "Action Flows"
---

# Action 'edit'
These methods are called in the following order:

![Edit action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/edit.drawio.svg)

1. `update_authorized_filter` called as before_action
   1. `update_authorized?` (or the method defined in conf.update.link.security_method if it's changed) is called to check the permission. If this method returns false, `update_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `edit`
   1. `do_edit` which uses `find_if_allowed` to load the record to be edited into @record instance variable, checking :update permission.
   2. `respond_to_action`, which will call the corresponding response method for edit action and the requested format

`do_edit` can be overrided, for example to change some attributes, or set form_ui for some columns depending on values of the edited record, or params of the request.

Then it will render these views:
* update.html.erb (only for HTML request)
  * _update_actions.html.erb (only for HTML request, if config.update.nested_links)
  * _update_form.html.erb
    * _base_form.html.erb
      * _form_messages.html.erb
        * _messages.html.erb (only for HTML request)
      * _form.html.erb
      * footer_extension partial if _base_form was called with this variable

The `_form` partial will render other partials depending on the columns, such as partials to render subforms, or partials for columns which have a partial form override.

The `_update_form` partial can be overrided and call render :super with local variables, to change some of default behaviour of _base_form:
* xhr: to force rendering as XHR request or HTML request instead of relying on the value of request.xhr?
* form_action: to use other action in the controller instead of `update`.
* method: to use other HTTP method instead of PATCH.
* cancel_link: use false to avoid adding a cancel link to the form.
* headline: to change the header of the form.

The `_base_form` partial can be overrided to render :super setting some variables to change the default behaviour, although it's used by many actions. Also, `_create_form` partial can be overrided copying the code, and passing more variables to `_base_form`. The following variables can be used, besides the ones explained above:
* multipart: to enable or disable rendering the form as multipart instead of relying in `active_scaffold_config.update.multipart`.
* persistent: can be `:optional`, `true` or `false`, instead of relying in `active_scaffold_config.update.persistent`.
* columns: an ActionColumns instance to use instead of `active_scaffold_config.update.columns`, build it with `active_scaffold_config.build_action_columns :update, [<list of columns>]`.
* footer_extension: to render a partial after footer buttons, inside the p tag with class form-footer.
* url_options: to change URL to submit the form, instead of default `params_for(action: :update)`.
* scope: to render the fields with an initial scope.
* floating_footer: to enable or disable the floating footer when form is too big to fit in the window, instead of relying on `active_scaffold_config.update.floating_footer`.
* submit_text: the text of submit button, which defaults to the value of `form_action` (update with default form_action).
* apply_text: the text of submit button which doesn't close the form, when persistent is enabled. The default value is `#{form_action}_apply` (update_apply with default form_action).
* body_partial: to use a different partial to render the fields in the form, instead of default `_form` partial.

# Action 'update'
When form is submitted, these methods are called in the following order:

![Update action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/update.drawio.svg)

1. `update_authorized_filter` called as before_action
   1. `update_authorized?` (or the method defined in conf.update.link.security_method if it's changed) is called to check the permission. If this method returns false, `update_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `update`
   1. `do_update`.
      1. `do_edit` which uses `find_if_allowed` to load the record to be edited into @record instance variable, checking :update permission.
      2. `update_save`, which accepts named argument `attributes` which defaults to `params[:record]`, and named argument `no_record_param_update` which can be used to prevent assigning values from attributes argument into @record, e.g. if the changes have been set in other way before.
         1. `update_record_from_params` to set the submitted values from `attributes` argument, unless is called with `true` in `no_record_param_update`.
         2. `before_update_save` will be called, an empty method which can be overrided to set other values before updating the record.
         3. It will run validations in the model and its associations which have been set from the submitted params. The method will stop here if validations fail.
         4. It will save the record and its associations which have been set.
         5. `after_update_save` will be called, an empty method which can be overrided to do something after updating a record. 
   2. `respond_to_action`, which will call the corresponding response method for update action and the requested format
      * For HTML request:
         * If record is saved successfully, it will call `return_to_main` which redirects to `main_path_to_return`, which defaults to list, or render the update form as edit action does if persistent is used.
         * If record fails to be created, it will render the update form with `update` view, as edit action does.
      * For XHR request will render `on_update` view.

