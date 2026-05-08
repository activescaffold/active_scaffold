---
title: "Edit Associated Action Flow"
category: "Action Flows"
---

# Action 'edit_associated'

When 'add another' button is clicked, a GET request to the action 'edit_associated' is sent to add a row. If subform has a select with existing records and 'add existing' button, it will send request to 'edit_associated' too, with ID of the selected record in the `associated_id` param. The request is sent to the controller of model which has the association, for example model A has subform for model B, adding row for B will send the request to the controller for A. If there is a nested subform for model C under B subform, adding a row for C will send the request to the controller for B.

In both cases, these methods are called in the following order:

![Edit_associated action flow](https://github.com/activescaffold/active_scaffold/blob/master/diagrams/edit_associated.drawio.svg)

1. edit_associated
   1. do_edit_associated, which sets instance variables:
      * @scope, with `scope` param, present if it's a nested subform.
      * @parent_record, the parent record of the added row, a model for the current controller.
      * @column for the `child_association` param, the association column where new row will be added, a column in the current controller.
      * @record, with the object for the added row.
      1. Depending if the row is added in a new record or existing record, ID param will be present or not, and different method is called to set @parent_record:
         * If ID param is present, the parent record is loaded with `find_if_allowed` checking permission for `:update`.
         * If there is no ID param, `new_parent_record` is called to build a new object for the parent model.
            1. `new_model` to create a new object
            2. It will set the values from constraints if controller is embedded, unless , and set the parent association if form was open on a nested scaffold.
      2. `find_associated_record` if `associated_id` param is present, for 'add existing' button.
      3. `build_associated` if there is no `associated_id` param, to build the object to add a row. If association is a through association, it gets the record in the through association if it's belongs_to or has_one, or create a new record if it's has_many, and builds the object for the new row in that object of the through association.

In both cases, @record will have @parent_record added to the reverse association, if reverse association is defined.

`build_associated` can be overrided, for example to change some attributes on the new record added to the subform, if attributes shouldn't be set when using 'add existing' button, although it can be done overriding `do_edit_associated` and checking if `@record` is a new record.

Then it will render the following view and partials:

* edit_associated.js.erb, with JS to add the new row to the subform.
  * _form_association_record.html.erb to render the HTML for the new row.