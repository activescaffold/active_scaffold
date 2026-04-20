---
title: "4.2 Released: Faster, Smarter and More Flexible"
date: "2026-02-03 15:19:19.000000000 +01:00"
categories:
- Releases
---

**ActiveScaffold 4.2** has been released, featuring major performance optimizations for large forms, integrated logical search, enhanced subform handling, and extended framework compatibility, including Rails 8.

------------------------------------------------------------------------

🚀 **Key Features & Improvements**
---------------------------------

### **Performance Boosts**

-   **Faster Form Operations**: Significant speed improvements for refreshing fields and saving large forms.
-   **Optimized Validation**: Faster validation for forms, especially with nested subforms and many records.
-   **Smart Preloading**: New `subform_includes` option in columns to optimize association loading, used on edit action, for a faster form rendering, especially when the form has long subforms which require other associations to load, or many nested subforms. A `preload_for_form` method in the controller will generate the associations to preload, and it can be overrided to add more associations, although `subform_includes` can be better and easier in most cases.
-   **Faster Rendering of Action Links**: Cache the generated HTML for action links in the rows, so the HTML is reused, rendering long lists or having many action links faster.

### **Improved Form Handling**

-   **Better Unauthorized Field Handling**: Unauthorized columns and subforms now display as read-only using the code from show action, so they look the same, and it's possible to display whole read-only subforms as tables.
-   **Flexible Field Updates**: Support for hashes in `update_columns`, so it's possible to refresh fields at different levels in the form, lower level refreshing fields on subforms (with nested subform support!), or upper level refreshing a field in the main form when a field in a subform changes.
-   **Enhanced Create Links on Associations**: Added `add_new_link` to open a create form on associations from the parent record, without open the list and then create, it will refresh the parent record.

### **Enhanced Search Capabilities**

-   **Logical Search Integration**: A new bridge that integrates with LogicalQueryParser adds support for logical searches, it supports full logical search with the operators supported by the gem, or simplified searches with intuitive 'all keywords' and 'any keyword' operators.

### **UI/UX Enhancements**

-   **Responsive Field Descriptions**: Option to hide descriptions by default, showing them on hover or click.
-   **Better Action Menus**: Dynamic action link groups in a submenu now open under the action link, inside the submenu.
-   **Improved File Management**: Enhanced ActiveStorage bridge to preserve existing files in `has_many_attachments`.
-   **Collection Association Enhancement**: `add_new` supported for collection associations too (defaults to popup mode, the only one supported).
-   **Improved Chosen Integration**: `add_new` supported as in select form UI.
-   **Support Click on Action Link Groups**: action link submenus can open with click instead of hover, and the lists with many action links may be rendered faster, as not all links needs to be rendered initially.

------------------------------------------------------------------------

🐛 **Important Fixes**
---------------------

-   **Frozen String Literals**: Added compatibility and magic comments for Ruby's frozen string literal mode
-   **TinyMCE with requierd**: Fixed validation errors for required textareas using TinyMCE

------------------------------------------------------------------------

🔧 **Extended Compatibility**
----------------------------

-   **Rails 8 Support**: Full compatibility with Rails 8.0 framework
-   **Bootstrap 5 Compatibility**: Updated tab components for seamless Bootstrap 5 integration
-   **Improved Localization**: Added translations for millisecond and microsecond prompts in jQuery UI datetime picker

------------------------------------------------------------------------

🛠 **For Developers**
--------------------

-   **Better Controller Customization**: Add `custom_modules` at config or global level for controller customization. An easier way to load modules which override ActiveScaffold methods. Also, support a controller method in `after_config_callbacks`.
-   **JS Setup Callbacks**: New `ActiveScaffold.setup_callbacks` array for executing functions on form/page load (whenever ActiveScaffold.setup is called).
-   **Better Sorting Control**: `sort_joins` column option for optimized SQL joins during sorting.
-   **Modern JavaScript**: Consolidated JS helpers for file upload bridges into `active_scaffold.js`, removing the JS mixed in the HTML tags.
-   **Subform Actions Helper**: New `active_scaffold_subform_record_actions` helper for adding custom actions to subform rows, supporting custom buttons on the subform.
-   **Flexible Configuration**: Enhanced customization options throughout the framework

------------------------------------------------------------------------

🚀 **Happy coding with ActiveScaffold!**