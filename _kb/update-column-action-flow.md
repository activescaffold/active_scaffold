---
title: "Update Column Action Flow"
category: "Action Flows"
---

# Action 'render_field' (GET request)
In-place editing usually displays a form using JS, but if `:ajax` is set in `inplace_edit`, it will use this action with GET request to render the form for in-place edit, which will call these methods in the following order:

![Render Field flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/render_field_get.drawio.svg)

1. `render_field`
   1. `render_field_for_inplace_editing`.
      1. It sets @column with the column being updated.
      2. It loads the record into @record instance variable, which uses find_if_allowed to load it.
         1. `find_if_allowed` is called to load the record, checking permission with :update and column's name.

Then it will render the following view:

1. `render_field_inplace.html.erb` is rendered to return the html field for the column

# Action 'update_column'
When form is submitted, these methods are called in the following order:

![Update Column flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/update_column.drawio.svg)

1. `update_column`
   1. `do_update_column`.
      1. It sets @column with the column being updated
      2. `record_for_update_column` is called to load the record into @record instance variable, which uses find_if_allowed to load it
         1. `find_if_allowed` is called to load the record, checking :read permission.
         2. It checks permission for :update and column's name, and stops the action if not allowed, but don't return 404 error.
      3. `value_for_update_column` to convert the submitted value to ruby object, with the same methods used internally by create and update actions.
      4. `before_update_save` will be called, after setting the value, before saving.
      5. If record is saved successfully and `inplace_edit_update` is set in the column, it will call one of these methods:
         * `do_list` if `inplace_edit_update` is `:table`.
         * `get_row` if `inplace_edit_update` is not `:table` but has value.
      6. `after_update_save` is called after saving the record

Then it will render the following view and partials:

1. `update_column.js.erb` is rendered to refresh the table, row, columns set in `update_columns` or the column being edited, depending on the value of `inplace_edit_update`.
   1. renders `_update_messages.js.erb` if updating failed
   2. depending on the value of `inplace_edit_update` renders:
      * if it's `:row` renders `_row` partial to refresh the row.
      * if it's `:table` renders `_list` partial to refresh the list table.
      * otherwise, updates the column, and renders `_update_columns.js.erb` if it's `:columns` and `update_columns` is set.
   3. If the column has calculation enabled, it will update the column calculation too.

