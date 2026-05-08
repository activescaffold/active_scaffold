---
title: "Create Action Flow"
category: "Action Flows"
---

# Action 'new'
These methods are called in the following order:

![New action flow](https://github.com/activescaffold/active_scaffold/raw/refs/heads/master/diagrams/new.drawio.svg)

1. `create_authorized_filter` called as before_action
   1. `create_authorized?` (or the method defined in conf.create.link.security_method if it's changed) is called to check the permission. If this method returns false, `create_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `new`
   1. `do_new` which uses `new_model` to setup the record used to render the create form. It will set the values from constraints if controller is embedded, and set the parent association if it's nested.
   2. `respond_to_action`, which will call the corresponding response method for new action and the requested format

`do_new` or `new_model` can be overrided, for example to set some default attributes in the form, `do_new` is only used in new action, while `new_model` is called from other actions too, such as create when form is submitted, field_search to render the form, to render create form when `always_show_create` is enabled, when changing a field in create form refreshes other field.

Then it will render these views:
* create.html.erb (only for HTML request)
  * _create_form.html.erb
    * _base_form.html.erb
      * _form_messages.html.erb
        * _messages.html.erb (only for HTML request)
      * _form.html.erb
      * footer_extension partial if _base_form was called with this variable

The `_form` partial will render other partials depending on the columns, such as partials to render subforms, or partials for columns which have a partial form override.

The `_create_form` partial can be overrided and call render :super with local variables, to change some of default behaviour of _base_form:
* xhr: to force rendering as XHR request or HTML request instead of relying on the value of request.xhr?
* form_action: to use other action in the controller instead of `create`.
* method: to use other HTTP method instead of POST.
* cancel_link: use false to avoid adding a cancel link to the form.
* headline: to change the header of the form.

The `_base_form` partial can be overrided to render :super setting some variables to change the default behaviour, although it's used by many actions. Also, `_create_form` partial can be overrided copying the code, and passing more variables to `_base_form`. The following variables can be used, besides the ones explained above:
* multipart: to enable or disable rendering the form as multipart instead of relying in `active_scaffold_config.create.multipart`.
* persistent: can be `:optional`, `true` or `false`, instead of relying in `active_scaffold_config.create.persistent`.
* columns: an ActionColumns instance to use instead of `active_scaffold_config.create.columns`, build it with `active_scaffold_config.build_action_columns :create, [<list of columns>]`.
* footer_extension: to render a partial after footer buttons, inside the p tag with class form-footer.
* url_options: to change URL to submit the form, instead of default `params_for(action: :create)`.
* scope: to render the fields with an initial scope.
* floating_footer: to enable or disable the floating footer when form is too big to fit in the window, instead of relying on `active_scaffold_config.create.floating_footer`.
* submit_text: the text of submit button, which defaults to the value of `form_action` (create with default form_action).
* apply_text: the text of submit button which doesn't close the form, when persistent is enabled. The default value is `#{form_action}_apply` (create_apply with default form_action).
* body_partial: to use a different partial to render the fields in the form, instead of default `_form` partial.

# Action 'create'
When form is submitted, these methods are called in the following order:


![Create action flow](https://github.com/activescaffold/active_scaffold/raw/refs/heads/master/diagrams/create.drawio.svg)

1. `create_authorized_filter` called as before_action
   1. `create_authorized?` (or the method defined in conf.create.link.security_method if it's changed) is called to check the permission. If this method returns false, `create_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
2. `create`
   1. `do_create` which accepts options hash, so it can be overrided and call super with the hash. `:attributes` key can be set in the options hash to use other attributes than params[:record].
      1. `new_model` will be called to create the record which will be saved. It must return an instance of the model, where the submitted values for active_scaffold_config.create.columns will be set.
      2. It will set the values from constraints if controller is embedded. It's called before the next method, because embedded in polymorphic association with multiple ids will set only the foreign type, and the form attributes will have the foreign id, so the foreign type must be set before.
      2. `update_record_from_params` to set the submitted values, from the `:attributes` key in the hash.
      3. Sets the parent association if it's nested.
      3. `before_create_save` will be called, an empty method which can be overrided to set other values before creating the record.
      4. It will run validations in the model and its associations which have been set from the submitted params.
      5. `create_save` will be called, unless `:skip_save` is set in the options hash.
         1. It will do nothing if validation failed.
         2. It will save the record and its associations which have been set.
         3. `after_create_save` will be called, an empty method which can be overrided to do something after creating a record. 
   2. `respond_to_action`, which will call the corresponding response method for create action and the requested format
      * For HTML request:
         * If record is created successfully, it will call `return_to_main` which redirects to `main_path_to_return`, which defaults to list, or redirect to an action for the current record if `active_scaffold_config.create.action_after_create` is defined, or render the create form as new action does if persistent is used.
         * If record fails to be created, it will render the create form with `create` view, as new action does.
      * For XHR request will render `on_create` view.

