---
title: "Announcing ActiveScaffold 4.3.0: Better Forms"
date: "2026-03-30 16:27:46.000000000 +02:00"
categories:
- Releases
---

We're excited to release ActiveScaffold 4.3.0, a major update packed with new features, improved flexibility, and better developer experience. This release focuses on enhanced form UI capabilities, improved translation support, and better asset pipeline compatibility.

------------------------------------------------------------------------

🚀 **Major New Features**
-------------------------

### **Enhanced Enum and Select Translations**

ActiveScaffold now supports nested translation keys for enum values and select options, providing more organized internationalization files. The system will look for translations in the pluralized column name before falling back to the traditional structure.

{% highlight ruby -%}
# In your model
class User < ApplicationRecord
  enum :status, [:active, :inactive]
end
{%- endhighlight %}

{% highlight yaml -%}
# config/locales/en.yml
en:
  activerecord:
    attributes:
      user:
        status: "User Status"
        # Old: enum values as columns
        active: "Active"
        inactive: "Inactive"
        # New: nested under pluralized column name
        statuses:
          active: "Currently Active"
          inactive: "Currently Inactive"
{%- endhighlight %}

### **Subform Column Configuration**

You can now specify which columns appear in subforms using the `:subform_columns` option. This works both in `form_ui_options` and directly in column options, and extends to horizontal and vertical show views.

{% highlight ruby -%}
# In your controller
config.columns[:address].form_ui = :subform
config.columns[:address].show_ui = :horizontal
# setting subform_columns in column's options apply to form UI and show UI
config.columns[:address].options = {
  subform_columns: [:street, :city, :zip_code, :country]
}
# Or using form_ui with options with horizontal/vertical layout
config.columns[:address].form_ui = :subform, {subform_columns: [:street, :city]}
{%- endhighlight %}

### **Multiple Layout Support for Action Columns**

Action columns now support multiple layouts, allowing forms to have columns in a multiple column layout. This provides greater flexibility in organizing form elements. Each column is an ActionColumn object too, so it supports the same methods and it's possible to add subgroups in a column.

{% highlight ruby -%}
config.create.columns.layout = :multiple
config.create.columns[0] = [:username, :email, :last_name, :first_name]
config.create.columns[1] = [:title, :company, :employee_type, :department]
# or adding a group without using index
config.create.columns << [:title, :company, :employee_type, :department]
# adding a subgroup
config.create.columns[1].add_subgroup 'Permissions' do |group|
  group << [:users, :orders, :quotes]
end
{%- endhighlight %}

### **New Form UI Types**

#### **Checkboxes Form UI**

A new list of checkboxes interface similar to the interface used for collection associations with `:select` form UI. It can be used with database columns, perfect for serialize columns saving a list of values.

{% highlight ruby -%}
# For a serialize column storing an array of roles
config.columns[:roles].form_ui = :checkboxes
config.columns[:roles].options = {
  options: ['admin', 'editor', 'viewer'],
  selected: ['editor']
}
{%- endhighlight %}

#### **Draggable Form UI for Non-Associations**

The draggable UI now works with non-association columns, enabling sortable interfaces for serialize columns.

{% highlight ruby -%}
# For a serialize column storing ordered items
config.columns[:playlist_order].form_ui = :draggable # same as :checkboxes, {draggable_lists: true}
config.columns[:playlist_order].options = {
  options: ['Song 1', 'Song 2', 'Song 3']
}
{%- endhighlight %}

### **List UI for Multiple Selection Types**

Added consistent list UI for the corresponding `select_multiple`, `draggable`, `checkboxes`, `select` and `radio` form UIs. This provides a more consistent view, displaying in list and show actions the same values as the form, for all different form UIs, not only `select` and `radio` as before.

------------------------------------------------------------------------

🔧 **Improvements and Fixes**
-----------------------------

### **Clear Form Column Conditionals**

Added `clear_form_column_if` — similar to `hide_form_column_if` but sends empty values instead of the previous values to clear database fields.

{% highlight ruby -%}
# Clears the field when condition is met
config.columns[:otp_info].clear_form_column_if = lambda do |column, record|
  record.mfa_type == 'otp'
end
{%- endhighlight %}

### **Better Exception Handling**

Improved error handling when rendering columns. Exceptions now provide complete backtraces, making debugging significantly easier.

### **Polymorphic and Nested Subform Fixes**

Fixed field rendering for polymorphic associations and nested subforms in edge cases, ensuring consistent behavior across complex associations.

### **Propshaft Compatibility**

ActiveScaffold now supports Propshaft with dartsass-rails, removing dependency on dartsass-sprockets. Simply add propshaft and dartsass-rails gems to your Gemfile:

{% highlight ruby -%}
# In your Gemfile
gem "propshaft"
gem "dartsass-rails"  # or dartsass-sprockets if not using propshaft
{%- endhighlight %}

------------------------------------------------------------------------

📦 **Upgrade Notes**
--------------------

When upgrading to 4.3.0, please note:

-   The new translation nesting is optional and backward compatible
-   Propshaft users need to ensure they have dartsass-rails gem in their Gemfile
-   If you're still using sprockets, add dartsass-sprockets gem; it's not a dependency as both systems are supported

To upgrade, update your Gemfile:

{% highlight ruby -%}
gem 'active_scaffold', '~> 4.3'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold
{%- endhighlight %}

------------------------------------------------------------------------

🙏 **Acknowledgments**
----------------------

Thanks to all contributors who made this release possible with their feedback, bug reports, and code contributions.

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
