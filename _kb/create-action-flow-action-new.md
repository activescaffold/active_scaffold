---
title: Create Action Flow Action 'new'
date: "2025-02-17 15:23:33.000000000 +01:00"
permalink: "/wiki-2/create-action-flow-action-new/"
---

These methods are called in the following order:

![]({{site.baseurl}}/assets/2025/02/new.drawio.svg)

1.  `create_authorized_filter` called as before\_action
```
1.  `create_authorized?` (or the method defined in conf.create.link.security\_method if it's changed) is called to check the permission. If this method returns false, `create_authorized_filter` will raise ActiveScaffold::ActionNotAllowed.
```
2.  `new`
```
1.  `do_new` which uses `new_model` to setup the record used to render the create form. It will set the values from constraints if controller is embedded, and set the parent association if it's nested.
2.  `respond_to_action`, which will call the corresponding response method for new action and the requested format
```
`do_new` or `new_model` can be overrided, for example to set some default attributes in the form, `do_new` is only used in new action, while `new_model` is called from other actions too, such as create when form is submitted, field\_search to render the form, to render create form when `always_show_create` is enabled, when changing a field in create form refreshes other field.

Then it will render these views:

-   create.html.erb (only for HTML request)
```
-   \_create\_form.html.erb
    -   \_base\_form.html.erb
        -   \_form\_messages.html.erb
            -   \_messages.html.erb (only for HTML request)
        -   \_form.html.erb
        -   footer\_extension partial if \_base\_form was called with this variable
```
The `_form` partial will render other partials depending on the columns, such as partials to render subforms, or partials for columns which have a partial form override.

The `_create_form` partial can be overrided and call render :super with local variables, to change some of default behaviour of \_base\_form:

-   xhr: to force rendering as XHR request or HTML request instead of relying on the value of request.xhr?
-   form\_action: to use other action in the controller instead of `create`.
-   method: to use other HTTP method instead of POST.
-   cancel\_link: use false to avoid adding a cancel link to the form.
-   headline: to change the header of the form.

The `_base_form` partial can be overrided to render :super setting some variables to change the default behaviour, although it's used by many actions. Also, `_create_form` partial can be overrided copying the code, and passing more variables to `_base_form`. The following variables can be used, besides the ones explained above:

-   multipart: to enable or disable rendering the form as multipart instead of relying in `active_scaffold_config.create.multipart`.
-   persistent: can be `:optional`, `true` or `false`, instead of relying in `active_scaffold_config.create.persistent`.
-   columns: an ActionColumns instance to use instead of `active_scaffold_config.create.columns`, build it with `active_scaffold_config.build_action_columns :create, [<list of columns>]`.
-   footer\_extension: to render a partial after footer buttons, inside the p tag with class form-footer.
-   url\_options: to change URL to submit the form, instead of default `params_for(action: :create)`.
-   scope: to render the fields with an initial scope.
-   floating\_footer: to enable or disable the floating footer when form is too big to fit in the window, instead of relying on `active_scaffold_config.create.floating_footer`.
-   submit\_text: the text of submit button, which defaults to the value of `form_action` (create with default form\_action).
-   apply\_text: the text of submit button which doesn't close the form, when persistent is enabled. The default value is `#{form_action}_apply` (create\_apply with default form\_action).
-   body\_partial: to use a different partial to render the fields in the form, instead of default `_form` partial.
