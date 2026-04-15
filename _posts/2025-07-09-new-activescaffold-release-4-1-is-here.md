---
title: "New ActiveScaffold Release, 4.1 is Here!"
date: "2025-07-09 17:42:24.000000000 +02:00"
categories:
- Releases
---

We are excited to announce the release of **ActiveScaffold 4.1**, a major update packed with new features, consolidating the features added on 4.0 and improving the integration with modern Rails applications. This version adds filters to the list action, popup mode for add\_new with a JS popup, consolidates tabbed feature added in 4.0, improved compatibility with Rails 7, improves grouped search, add few more small features and optimizes refreshing columns in a form, when disabling the form while the fields are refreshed is not needed (for example to refresh read only fields).

------------------------------------------------------------------------

**What’s New in ActiveScaffold 4.0?**
-------------------------------------

-   **Better Support for Rails 7:** ActiveScaffold 4.1 is fully compatible with Rails 7, dropping support for older version 6.1, and migrating to dart sass.
-   **Improved tabbed interface:** Tabbed\_by is supported in columns group of show action too, so it can look like the form, but read only.
-   **Improved add\_new:** The text for the links can be changed in the form UI options, using a hash for add\_new, and a new mode :popup is added, using a JS dialog, as :popup position does for action links.
-   **Filters:** Filters are now a first-class setting in ActiveScaffold, so they don't need to be added as action links to :index action, and the conditions are handled next to the filter definition. No more overriding of conditions\_for\_collection or beginning\_of\_chain to define the filter condition.
-   **Improved grouped search:** Field search supported a limited group by feature, it's more powerful now, so grouping by more than one column is supported, virtual columns can be displayed in the grouped search defining the DB columns to be used for the calculation, and support more SQL functions than the supported by Rails in the calculate method.
-   **Faster typing while refreshing a field:** If the refreshed fields can't be edited, or you don't worry about user editing a field which will be replaced (for example, because the refreshed fields are far from the changed field), disabling the form while refreshing fields can be disabled.
-   **Enhanced Components:** Add support for prompt on action links, as an easy and fast way to request and submit an string (comment, reason, ...), support embedding with multiple values in a constraint, defining empty\_field\_text per column, and support overriding with class prefix in another helper (sorted\_association\_options\_find), which is useful when clear\_helpers is not used.
-   **Improved Bridge Support:** Better integration with TinyMCE, supporting setup option in tinymce config with a function.
-   **Bug Fixes & Stability Improvements:** Addressed multiple issues reported by the community to enhance reliability and ease of use.

------------------------------------------------------------------------

### **How to Upgrade?**

If you’re using an older version of ActiveScaffold, upgrading is simple. Add or update the gem in your `Gemfile`:

```
gem 'active_scaffold', '~> 4.1'
```
Then, run:

```
bundle update active_scaffold
```
------------------------------------------------------------------------

### **Breaking Changes**

Support for rails 6.1 and ruby 3.0 has been removed.

The active\_scaffold\_habtm\_joins method has been renamed to active\_scaffold\_joins, and it's deprecated now.

------------------------------------------------------------------------

### **What’s Next?**

We are starting to work on the support for rails 8.0, and new features, such as logical search. Future updates may continue improving performance, and will add new features, and enhance integration with modern Rails workflows. If you have feedback or feature requests, we welcome contributions on [GitHub](https://github.com/activescaffold/active_scaffold).

------------------------------------------------------------------------

### **Try It Now!**

Download **ActiveScaffold 4.1** today and experience the improvements firsthand. Stay tuned for more updates and upcoming tutorials on how to make the most of the new features.

------------------------------------------------------------------------

🚀 **Happy coding with ActiveScaffold!**
