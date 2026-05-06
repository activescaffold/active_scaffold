---
title: Create Action Flow Action 'create'
date: "2025-02-17 15:33:16.000000000 +01:00"
permalink: "/wiki-2/create-action-flow-action-create/"
---

When form is submitted, these methods are called in the following order:

![Create action flow]({{site.baseurl}}/assets/2025/02/create.drawio.svg)

1.  `create_authorized_filter` called as before\_action
```
1.  `create_authorized?` (or the method defined in conf.create.link.security\_method if it's changed) is called to check the permission. If this method returns false, `create_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
```
2.  `create`
```
1.  `do_create` which accepts options hash, so it can be overrided and call super with the hash. `:attributes` key can be set in the options hash to use other attributes than params\[:record\].
    1.  `new_model` will be called to create the record which will be saved. It must return an instance of the model, where the submitted values for active\_scaffold\_config.create.columns will be set.
    2.  It will set the values from constraints if controller is embedded. It's called before the next method, because embedded in polymorphic association with multiple ids will set only the foreign type, and the form attributes will have the foreign id, so the foreign type must be set before.
    3.  `update_record_from_params` to set the submitted values, from the `:attributes` key in the hash.
    4.  Sets the parent association if it's nested.
    5.  `before_create_save` will be called, an empty method which can be overrided to set other values before creating the record.
    6.  It will run validations in the model and its associations which have been set from the submitted params.
    7.  `create_save` will be called, unless `:skip_save` is set in the options hash.
        1.  It will do nothing if validation failed.
        2.  It will save the record and its associations which have been set.
        3.  `after_create_save` will be called, an empty method which can be overrided to do something after creating a record.
2.  `respond_to_action`, which will call the corresponding response method for create action and the requested format
    -   For HTML request:
        -   If record is created successfully, it will call `return_to_main` which redirects to `main_path_to_return`, which defaults to list, or redirect to an action for the current record if `active_scaffold_config.create.action_after_create` is defined, or render the create form as new action does if persistent is used.
        -   If record fails to be created, it will render the create form with `create` view, as new action does.
    -   For XHR request will render `on_create` view.
```
