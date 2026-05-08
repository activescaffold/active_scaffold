---
title: "Options for add_new"
category: "Advanced"
---

When used in `:select` form_ui, the value for `:add_new` may be a hash with different options:

* `:mode` which may be
  * `:subform` (default if no mode is set), the same as using `add_new: true`, will render a hidden subform.
  * `:popup` which will render a link to open a JS popup (with jquery ui dialog, or other JS library if `ActiveScaffold.open_popup` is overrided)
* `:types` for polymorphic belongs_to, it must be an array with the model names which will get the 'Create New' link when is selected in the foreign_type column.
* `:layout`, when using `:subform` mode, the layout for the subform can be set with this option, instead of using the layout set in subform.layout of the associated controller.
{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :select, {add_new: {mode: :popup, layout: :vertical}}
{%- endhighlight %}
![layout example](/assets/screenshots/add-new-layout-example.png)
* `:hide_subgroups`, when using `:subform` mode, the column subgroups of the subform can be hidden. By default, subgroups are visible, with no link to hide, but with this option the subgroups will be hidden and there will be a link to show them.  
![subgroup hidden example](/assets/screenshots/add-new-subgroup-hidden.png)
![subgroup visible example](/assets/screenshots/add-new-subgroup-visible.png)
* `:add_new_text`, in both `:subform` and `:popup` modes, will have the text to display instead of 'Create New'. It may be a symbol to use translation in `:active_scaffold` scope, or a string to avoid translations.
* `:add_existing_text`, in `:subform` mode, will have the text to display instead of 'Add Existing', to hide the subform and show the field UI again. It may be a symbol to use translation in `:active_scaffold` scope, or a string to avoid translations.
* `:security_method` is the name of a controller method to be called to check if the link to open a popup is allowed, it's used only in `:popup` mode. If no `:security_method` is set, it will check if the association's model is authorized for create (calling `model.authorized_for?(crud_type: :create)`).

## Helpers which can be overrided
`active_scaffold_new_record_klass(column, record, **options)`, returns the model of the association, when it's a polymorphic `belongs_to`, it will get the model from the `foreign_type` column, and will return nil if the `:types` option is provided and the model is not included on it. It can be overrided to support creating a record for a different model, it supports overriding with class prefix, with the name of the model having the column with `:add_new` option.

`active_scaffold_new_record_url_options(column, record)`, returns a hash used to generate the url for the create form opened in `:popup` mode. By default returns `{embedded: {constraints: {model_name: record_id}}}` so the form is constrained on the record having the column with `:add_new` option. The url will be generated to the controller for the model returned by `active_scaffold_new_record_klass`, `:new` action, `:from_field` param with the id of this field (so after record is created the JS response can add the new record to the field), `:parent_model` with the model's name of the current record, and `:parent_column` with this column's name. This helper method can be overrided to add other parameters, or change the default ones, the returned hash may have this keys to override the default values. It supports overriding with class prefix, with the name of the model having the column with `:add_new` option.

{% highlight ruby -%}
def active_scaffold_new_record_url_options(column, record)
  if column == :address
    super.merge(other_param: :xxx)
  else
    super
  end
end
{%- endhighlight %}

`new_option_from_record(record)` is a helper called from the JS response on create action, when called with `:from_field` param (for the `:popup` mode), to return the label to use in the field (`:select` form UI or `:record_select` form UI) and the value to use in the field, which defaults to `to_label` and the `id`. It can be overrided to use different methods for label and value, and it can check where will be added with `params[:parent_model]` and `params[:parent_column]`.