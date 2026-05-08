---
title: "Render Field Action Flow"
category: "Action Flows"
---

# Action 'render_field' (POST request)
When a column in a form is changed, and `:update_columns` has been set, it will send a POST request to `render_field` action, to refresh the columns set in `:update_columns`, if the refreshed columns have `:update_columns`, they will be refreshed too, recursively, but avoiding refreshing an already refreshed column to avoid infinite loops.

When the changed column is in a subform, the request is sent to the controller of the model in the subform, not the controller which loaded the form.

The request may include only the changed value, or the whole form if `send_form_on_update_column` was enabled in the column, which is needed when the refreshed columns need to read values from other columns than the changed one. The action may be complex, depending on different settings, so it's a bit complicated to explain. The following methods may be called in the following order:

![Render Field flow](https://github.com/activescaffold/active_scaffold/raw/refs/heads/master/diagrams/render_field_post.drawio.svg)

1. `render_field`
   1. `render_field_for_update_columns`.
      1. It sets different instance variables:
         * @column with the column which triggered the refreshing, the one which was changed
         * @columns with the columns to fresh (from @column.update_columns)
      1. `process_render_field_params`, which sets other instance variables:
         * @source_id with the HTML's id of the changed field
         * @scope with the param :scope, sent when the field triggering the request is in a subform
         * @form_action, which will be :subform if @scope was sent, the param :form_action if was sent, :update if :id param was sent, or :create
         * @main_columns, with the columns for the @form_action (active_scaffold_config.<@form_action>.columns)
      2. Depending on @column.send_form_on_update_column, it will call one of the following methods, and set the returned value in @record:
         * If true, the form was sent, and calls `updated_record_with_form`.
            1. It will load the record being updated in the form with `find_if_allowed` if id is present, checking :read permission.
            1. `new_model` to build a new object, to prevent saving to DB when assigning some association with the form values (e.g. has_and_belongs_to_many associations).
            2. `copy_attributes` to copy values from the saved record into the new object, if :id param was sent.
            3. It will set the values from constraints if controller is embedded, and set the parent association if it's nested.
            4. `update_record_from_params` to assign the submitted values from the form, so the object has the current state in the form when refreshing the fields.
         * If false, only the value was sent, and calls `updated_record_with_column`.
            1. It initializes record in different ways:
               * If :id param was sent:
                  1. The method will load the record being updated in the form with `find_if_allowed` if id is present, checking :read permisison.
                  2. `copy_attributes` to copy values from saved record into new object.
               * If :id param wasn't sent (from create or field search form):
                  1. `new_model`.
                  2. It will set the values from constraints if controller is embedded, and column was not in a subform.
            2. It will set the parent association if it's nested.
            3. `update_column_from_params` to assign the submitted value in to the changed column, unless column is a singular association, from a field search form, and submitting an array (because it's using select with multiple attribute), which will set @value, as can't assign an array to a singular association.
      3. `setup_parent` to assign the parent record when changed field is in a subform (but not nested subform). It's a complex method, which will build the parent record in a new object, and set into the parent association in @record.
         1. `copy_attributes` to copy attributes from record in DB if it's saved.
         2. `update_record_from_params` to copy attributes from submitted values if @column.send_form_on_update_column was enabled.
         3. It will set the values from constraints if controller is embedded, and record wasn't saved yet.
      4. `after_render_field` which gets the record which got the column changed, and the changed column. It's an empty method to be overrided, adding custom code needed when a column changes, before rendering the fields to be refreshed.

Then it will render the following view and partials:

* `render_field.js.erb`
  * `_render_field.js.erb` is rendered for each column to be refreshed, with local variables `scope`, `source_id` and `render_field` (the column to be refreshed). The refreshed columns are saved in `@rendered` instance variable to prevent infinite loop if 2 columns refreshes each other, or avoid refreshing the same column more than once.

