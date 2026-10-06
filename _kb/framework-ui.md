---
title: "Customizing UI Markup and Integrating CSS Frameworks"
category: "Customization"
published: true
---

ActiveScaffold provides default HTML and CSS, but applications may need different
tags, classes, ARIA attributes, or wrapper structures to integrate a theme or a
CSS framework such as Bootstrap, daisyUI, or Tailwind CSS.

The UI rendering API has two levels:

1. Named UI elements configure tags and HTML attributes without replacing a
   template or helper.
2. Focused rendering helpers can be overridden when the required HTML structure
   cannot be expressed by changing one element.

Configure UI elements during application initialization. The registry is global,
so it should not be changed during a request.

## Configuring named UI elements

`ActiveScaffold.ui_elements` contains the definitions used by `as_element` and
`as_element_attributes`. An element definition can contain:

- `:tag`, the tag rendered by `as_element`.
- `:attributes`, default HTML attributes merged into attributes supplied while
  rendering.
- `:proc`, dynamic code returning `[tag, attributes]`.

A proc takes the place of the static tag and attributes. It executes in the view
context, so it may call view and ActiveScaffold helper methods.

The public setup methods are:

{% highlight ruby -%}
# Replace only the tag.
ActiveScaffold.set_element_tag(:form_footer, :div)

# Smart-merge attributes. Classes are appended and nested hashes are merged.
ActiveScaffold.add_element_attributes(
  :form_submit,
  class: 'btn btn-primary',
  data: {controller: 'submit'}
)

# Replace all configured attributes for the element.
ActiveScaffold.set_element_attributes(
  :message_close,
  type: :button,
  class: 'btn-close',
  aria: {label: 'Close'}
)

# Replace the complete definition, including any old proc.
ActiveScaffold.set_element(
  :message_close,
  tag: :button,
  attributes: {
    type: :button,
    class: 'btn-close',
    aria: {label: 'Close'}
  }
)

# Set dynamic tag and attributes on the existing definition.
ActiveScaffold.set_element_proc(:action_link) do |context|
  [nil, {class: context[:authorized] ? 'enabled' : 'disabled'}]
end

# Replace the complete definition with a proc.
ActiveScaffold.set_element(:action_link) do |context|
  [nil, {class: context[:authorized] ? 'enabled' : 'disabled'}]
end
{%- endhighlight %}

`set_element` accepts either a tag and attributes or a block, not both.

### Merge order

ActiveScaffold resolves an element in this order:

1. If the definition has a proc, call it and use its tag and attributes;
   otherwise use the static tag and attributes.
2. Smart-merge the attributes supplied by the rendering helper or template.

Attributes supplied while rendering therefore remain present. ActiveScaffold
uses this for classes and attributes required by its JavaScript behavior, while
an integration adds presentation classes through the registry.

`set_element_attributes` replaces the attributes stored in the registry, but it
does not suppress attributes supplied later by the rendering call.

### Attribute-only elements

Some keys configure an element whose tag is fixed by a Rails helper or by valid
table markup. Examples include `form_control`, `action_link`, `list_table`, and
`list_records`. Their definitions should return or configure attributes; their
tag is ignored.

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :list_table,
                                      class: 'table table-striped'
{%- endhighlight %}

## Dynamic element context

The hash received by an element proc depends on the element.

### Form and field-search elements

Form elements receive the column. Controls also receive their configured UI:

{% highlight ruby -%}
ActiveScaffold.set_element_proc(:form_control) do |context|
  css_class =
    case context[:form_ui]
    when :select
      'form-select'
    when :checkbox
      'form-check-input'
    else
      'form-control'
    end

  [nil, {class: css_class}]
end

ActiveScaffold.set_element_proc(:search_control) do |context|
  css_class = context[:search_ui] == :select ? 'form-select' : 'form-control'
  [nil, {class: css_class}]
end
{%- endhighlight %}

`form_ui_class(form_ui)` remains available as an overridable helper for the
class on the outer `form_element`. `form_control` configures the options passed
to the actual input, select, or textarea.

The default form field structure uses these elements:

- `form_element`, the field's outer item in the form.
- `form_attribute`, the wrapper around label and field.
- `form_attribute_label`, the label wrapper.
- `form_attribute_field`, the control and description wrapper.
- `form_control`, attributes passed to the form control.
- `form_field_description` and `form_field_description_close`.

Field search has parallel `search_attribute`, `search_attribute_label`,
`search_attribute_field`, and `search_control` elements.

If a framework requires a different relationship or ordering for the label,
control, help text, and validation feedback, override `form_attribute_html` or
`search_attribute_html` in an application helper. Those helpers receive the
already-rendered pieces, so an override does not need to replace field selection
or input-generation logic.

## Action links

The `action_link` element is attribute-only. Its proc receives:

- `:link`, the action-link configuration object.
- `:record`, when rendering a member link.
- `:options`, the rendering options.
- `:authorized`, always `true` or `false`.

The element attributes are applied after `action_link_html_options`, to preserve
that method as a focused override point.

{% highlight ruby -%}
ActiveScaffold.set_element_proc(:action_link) do |context|
  link = context[:link]

  variant =
    if !context[:authorized]
      'btn-secondary disabled'
    elsif link.crud_type == :delete
      'btn-danger'
    elsif link.crud_type == :create
      'btn-primary'
    else
      'btn-secondary'
    end

  [nil, {class: "btn #{variant}"}]
end
{%- endhighlight %}

Action-link HTML may be cached. Basing presentation on the link definition and
authorization state is safe; avoid generating attributes from arbitrary values
on an individual record unless action-link caching is disabled or the value is
represented in the cache key.

Other configurable action elements include `action_link_item`,
`action_link_group`, `action_link_group_title`, `action_link_group_content`,
`action_link_separator`, `dynamic_action_group`, and
`dynamic_action_group_element`.

When a framework needs a substantially different action hierarchy,
`display_action_links`, `render_action_link_group`, and
`action_link_element_attributes` remain overridable helpers.

## Pagination and Bootstrap

Pagination deliberately combines configurable elements with rendering hooks.
The page-window calculation remains in `pagination_ajax_links`; integrations do
not need to duplicate it.

The following elements can configure the link and current-page markup:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :pagination_link,
                                      class: 'page-link'
ActiveScaffold.add_element_attributes :pagination_active_page,
                                      class: 'page-link',
                                      aria: {current: 'page'}
{%- endhighlight %}

The `pagination_link` proc receives `:page_number` and `:text`. `:text` is set to
`:previous` or `:next` for those links and is `nil` for numbered links.

Bootstrap requires a structure such as `nav > ul.pagination > li.page-item`.
That requires wrappers around the whole group and around each item, so it should
be implemented with helper overrides rather than only element attributes:

{% highlight ruby -%}
module ApplicationHelper
  def pagination_html(&block)
    items = super(&block)

    content_tag :nav, aria: {label: 'Pagination'} do
      content_tag :ul, items, class: 'pagination'
    end
  end

  def pagination_ajax_link(...)
    content_tag :li, super, class: 'page-item'
  end

  def pagination_active_page(...)
    content_tag :li, super, class: 'page-item active'
  end

  def pagination_gap(...)
    content_tag :li, class: 'page-item disabled' do
      content_tag :span, super, class: 'page-link'
    end
  end
end
{%- endhighlight %}

`pagination_html` contains the previous, numbered, gap, current, and next page
items. The loading indicator is outside it, so a `ul` produced by an integration
does not receive an image as a direct child.

The outer `pagination_links` element remains responsible for the
ActiveScaffold pagination container and the `auto-paginate` behavior.

## Responsive tables

Table tags such as `thead`, `tbody`, and `tr` cannot generally be replaced with
arbitrary tags without producing invalid HTML. Their named UI elements configure
attributes instead:

- `list_table`
- `list_table_head`
- `list_table_head_row`
- `list_records`
- `list_messages`
- `list_messages_container`
- `list_calculations`
- `record_actions_cell`
- `record_action_links`

Bootstrap responsive tables need an additional wrapper around the table. Override
`list_table_html`, whose default implementation returns the captured table
unchanged:

{% highlight ruby -%}
module ApplicationHelper
  def list_table_html(&block)
    content_tag :div, super(&block), class: 'table-responsive'
  end
end
{%- endhighlight %}

## Complete UI element reference

The type in the following tables describes how ActiveScaffold uses each element:

- **Tag + attributes** means that `as_element` renders the element. Its tag and
  attributes can both be configured.
- **Attributes only** means that another helper or template owns the tag. Only
  its HTML attributes are configurable; a configured tag is ignored.

### List, messages, and pagination

| Element | Type | Used for |
|---|---|---|
| `list` | Tag + attributes | Outermost component containing one ActiveScaffold list, including its header and content. |
| `list_header` | Tag + attributes | Header area above the list content. |
| `list_title` | Tag + attributes | Heading containing the configured list label. |
| `list_actions` | Tag + attributes | Container for collection action links in the list header. |
| `filters` | Tag + attributes | Container for configured list filters. It is omitted when there are no visible filters. |
| `before_header_table` | Tag + attributes | Table containing inline search, create, or other action adapters inserted above the list. |
| `list_content` | Tag + attributes | Main content area below the header, containing the list and its footer. |
| `list_table` | Attributes only | Main table containing headings, messages, records, and calculations. |
| `list_table_head` | Attributes only | `thead` of the main list table. |
| `list_table_head_row` | Attributes only | Row containing the list column headings. |
| `list_records` | Attributes only | `tbody` containing record rows and the data used to refresh a record. |
| `list_messages` | Attributes only | `tbody` containing filtered, applied-filter, empty-list, and action messages. |
| `list_messages_container` | Attributes only | Table cell spanning the list columns and containing list messages. |
| `list_action_messages` | Tag + attributes | Target updated with success, warning, and error messages produced by list actions. |
| `filtered_message` | Tag + attributes | Notice shown when the result set is constrained by the legacy filtered state. |
| `applied_filters_message` | Tag + attributes | Notice describing filters currently applied to the list. |
| `empty_message` | Tag + attributes | Message displayed when the list has no records. |
| `message_reset` | Tag + attributes | Wrapper for the action that clears a search or applied filters from a list message. |
| `message_close` | Tag + attributes | Control used to dismiss flash and server-error messages. |
| `server_error` | Tag + attributes | Message shown when an Ajax action receives an internal server error. |
| `info_message` | Tag + attributes | Informational flash message. |
| `warning_message` | Tag + attributes | Warning flash message. |
| `error_message` | Tag + attributes | Error flash message. |
| `list_footer` | Tag + attributes | Footer below the records table, containing the record count and pagination. |
| `list_found` | Tag + attributes | Record-count sentence in the list footer. |
| `list_found_count` | Tag + attributes | Numeric record count inside `list_found`; JavaScript updates this value when rows change. |
| `list_calculations` | Attributes only | Table-footer row containing configured column calculations. |
| `pagination_links` | Tag + attributes | Outer pagination area, including the loading indicator and the output of `pagination_html`. |
| `pagination_link` | Attributes only | Anchor generated for a numbered, previous, or next page link. |
| `pagination_active_page` | Tag + attributes | Non-clickable representation of the current page. |
| `record_actions_cell` | Attributes only | Actions cell at the end of a record row. |
| `record_action_links` | Attributes only | Inner table arranging the loading indicator and member action links in a record row. |

### Action links and action groups

| Element | Type | Used for |
|---|---|---|
| `action_link_group` | Tag + attributes | Wrapper for a configured group of action links. Its default tag depends on whether the group is top-level or nested. |
| `action_link_separator` | Tag + attributes | Separator inserted between configured links or groups. Its default tag depends on the action-link level. |
| `action_link_group_title` | Tag + attributes | Visible label or toggle for an action-link group. |
| `action_link_group_content` | Tag + attributes | Container holding the nested links in an action-link group. |
| `action_link` | Attributes only | Authorized or unauthorized action anchor. Its proc receives the link, record, rendering options, and authorization state. |
| `action_link_item` | Tag + attributes | Item wrapping an individual action link inside a nested action group. |
| `dynamic_action_group` | Tag + attributes | Menu of member actions loaded dynamically after its action link is activated. |
| `dynamic_action_group_element` | Tag + attributes | Item wrapping each link in a dynamically loaded action menu. |

### Search and field search

| Element | Type | Used for |
|---|---|---|
| `search_form` | Attributes only | Form used by the simple text-search action. |
| `search_field` | Attributes only | Search input used by simple and live search. |
| `search_control` | Attributes only | Input, select, or textarea generated for an individual field-search column. Its proc receives the column and `search_ui`. |
| `search_submit` | Attributes only | Submit input for the simple search form. |
| `search_reset` | Attributes only | Link that clears simple-search terms. |
| `field_search_form` | Attributes only | Form used by field search. |
| `field_search_fields_columns` | Tag + attributes | Outer container for a field-search layout with multiple groups of columns. |
| `field_search_fields_container` | Tag + attributes | Container holding a group of field-search fields, including the collapsible optional-fields group. |
| `field_search_subsection` | Tag + attributes | Wrapper for a field-search subsection or the optional-fields subsection. |
| `field_search_element` | Tag + attributes | Outer item for one field-search column. |
| `field_search_submit` | Attributes only | Submit input for field search. |
| `field_search_reset` | Attributes only | Link that resets or clears field search. |
| `field_search_footer` | Tag + attributes | Footer containing field-search submit, reset, and loading controls. |

The label-and-control structure inside each field-search element is configured by
`search_attribute`, `search_attribute_label`, and `search_attribute_field`, which
are listed with the shared form elements below.

### Forms, form fields, and subforms

| Element | Type | Used for |
|---|---|---|
| `form` | Attributes only | Create or update form generated by Rails. |
| `form_title` | Tag + attributes | Heading displayed at the top of a create, update, or add-existing form. |
| `form_messages_container` | Tag + attributes | Container for validation errors and action messages belonging to a form. |
| `form_fields_columns` | Tag + attributes | Outer container for a form layout with multiple groups of columns. |
| `fields_container` | Tag + attributes | Container holding one group of form fields. |
| `form_subsection` | Tag + attributes | Outer item for a configured subsection of form columns. |
| `form_subsection_header` | Tag + attributes | Heading and optional visibility control for a form subsection. |
| `subform` | Tag + attributes | Outer form item containing an association rendered as a subform. |
| `subform_header` | Tag + attributes | Heading for an association subform. |
| `subform_footer` | Tag + attributes | Footer containing controls that create, replace, or add associated records. |
| `subform_record_remove` | Attributes only | Link that marks or removes an editable record from a collection subform. |
| `subform_record_remove_reason` | Tag + attributes | Non-clickable explanation shown when a subform record cannot be removed. |
| `subform_create_another` | Attributes only | Link that creates another record for a collection association. |
| `subform_replace_with_new` | Attributes only | Link that replaces a singular associated record with a new record. |
| `subform_add_existing` | Attributes only | Link that adds or selects an existing associated record. |
| `form_element` | Tag + attributes | Outer item for one form column, including required, UI-type, and column classes. |
| `form_attribute` | Tag + attributes | Wrapper around the label and field produced by the default `form_attribute_html`. Its proc receives the column. |
| `form_attribute_label` | Tag + attributes | Label wrapper inside `form_attribute`. Its proc receives the column. |
| `form_attribute_field` | Tag + attributes | Wrapper containing the control, description, and collapsible target inside `form_attribute`. Its proc receives the column. |
| `search_attribute` | Tag + attributes | Wrapper around the label and control produced by the default `search_attribute_html`. Its proc receives the column. |
| `search_attribute_label` | Tag + attributes | Label wrapper inside `search_attribute`. Its proc receives the column. |
| `search_attribute_field` | Tag + attributes | Control wrapper inside `search_attribute`. Its proc receives the column. |
| `form_control` | Attributes only | Input, select, or textarea generated for an individual form column. Its proc receives the column and `form_ui`. |
| `form_field_description` | Tag + attributes | Help or description associated with a form field. |
| `form_field_description_close` | Tag + attributes | Control inside a field description used to hide the description. |
| `form_footer` | Tag + attributes | Footer containing form submit, apply, cancel, loading, and extension controls. |
| `form_submit` | Attributes only | Primary create or update submit input. |
| `form_apply` | Attributes only | Submit input that saves while keeping a persistent form open. |
| `form_cancel` | Attributes only | Link that cancels or closes a form. |
| `field_add_new_subform` | Attributes only | Link that switches a singular association field between selecting an existing record and creating a new subform record. |
| `field_add_new_popup` | Attributes only | Link that opens a create form in a popup and adds the created record to an association field. |

### Show view

| Element | Type | Used for |
|---|---|---|
| `show_title` | Tag + attributes | Heading of the show view. |
| `show_actions` | Tag + attributes | Container for member action links displayed above or below a show view. |
| `show_columns_block` | Tag + attributes | Main container for the columns displayed by the default vertical show layout. |
| `show_label_block` | Tag + attributes | Label for one show column or group. |
| `show_columns_group` | Tag + attributes | Container for grouped show columns. |
| `show_value_block` | Tag + attributes | Displayed value of one show column. |
| `show_footer` | Tag + attributes | Footer containing the show view's close control. |
| `show_cancel` | Attributes only | Link that closes the show view or returns to the list. |

The tables above describe all keys in the current registry. You can also use
`ActiveScaffold.ui_elements.keys` to inspect the set supported by the installed
ActiveScaffold version.

## When to use each extension point

Use `add_element_attributes` when the existing tag and structure are correct and
the integration only needs more classes or attributes.

Use `set_element_tag`, `set_element_attributes`, or `set_element` when the
existing configured defaults must be replaced.

Use an element proc when tag or attributes depend on supplied rendering context.

Override a focused rendering helper when elements must be reordered, nested, or
wrapped. Prefer calling `super` so ActiveScaffold continues to own authorization,
pagination calculations, generated URLs, field selection, and other behavior.

Use a template override only when the required structure is broader than the
available element and helper hooks. See [Template Overrides](/doc/template-overrides/).
