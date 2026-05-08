---
title: "Render Field Action Flow Adding a Tab"
category: "Action Flows"
---

# Action 'render_field' adding a tab (GET request)

When `tabbed_by` is set in a group of columns, to render a [tabbed group of columns](/doc/tabbed-group-of-columns/), clicking on 'add tab' link will send a GET request to `render_field` action to add the new tab, passing the group's name in the `column` parameter, and also the `tabbed_by` and the selected record for `tabbed_by` in the `value` parameter.

The following methods may be called in the following order:

![Render Field adding tab flow](https://github.com/activescaffold/active_scaffold/raw/refs/heads/master/diagrams/render_field_add_tab.drawio.svg)

1. `render_field`
   1. `add_tab`.
      1. `process_render_field_params`, which sets different instance variables:
         * @source_id with the HTML's id of the changed field
         * @scope with the param :scope, sent when the field triggering the request is in a subform
         * @form_action, which will be :subform if @scope was sent, the param :form_action if was sent, :update if :id param was sent, or :create
         * @main_columns, with the columns for the @form_action (active_scaffold_config.<@form_action>.columns)
      2. It sets @column with the group of columns, from the :column param.
      2. `updated_record_with_form`:
            1. It will load the record being updated in the form with `find_if_allowed` if id is present, checking :read permission.
            1. `new_model` to build a new object, to prevent saving to DB when assigning some association with the form values (e.g. has_and_belongs_to_many associations).
            2. `copy_attributes` to copy values from the saved record into the new object, if :id param was sent.
            3. It will set the values from constraints if controller is embedded, and set the parent association if it's nested.
            4. `update_record_from_params` to assign the submitted values from the form, so the object has the current state in the form when refreshing the fields.

Then it will render the following view and partials:

* `add_tab.js.erb`
  * `_form.html.erb` to render the columns for the new tab.

The `_form` partial will render other partials depending on the columns, such as partials to render subforms, or partials for columns which have a partial form override. Check the diagram in [new action in create action flow](/doc/create-action-flow/#action-new) or [edit action in update action flow](/doc/update-action-flow/#action-edit) to see what other partials or methods are used to render the columns in a form.