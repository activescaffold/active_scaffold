---
title: "ActiveScaffold 4.0 is Here!"
date: "2025-01-16 06:12:00.000000000 +01:00"
categories:
- Releases
---

We are excited to announce the release of **ActiveScaffold 4.0**, a major update packed with new features, performance improvements, and better integration with modern Rails applications. This version brings enhanced UI components, improved compatibility with Rails 7, and optimizations to make CRUD operations even more efficient.

------------------------------------------------------------------------

**What’s New in ActiveScaffold 4.0?**
-------------------------------------

-   **Full Support for Rails 7:** ActiveScaffold 4.0 is fully compatible with Rails 7, ensuring smooth performance with the latest framework updates.
-   **Enhanced UI Components:** Improved handling of form inputs, improved field search and accessibility refinements for a better user experience.
-   **Performance Optimizations:** Faster page loads and query execution, especially for large datasets.
-   **Safer code with thread-safety:** Thread safety fully integrated, it isn't an optional feature anymore, no more performance issues with thread-safety with 4.0.
-   **More Flexible Customization:** Additional configuration options for form and list UIs, giving developers more control over the look and behavior of ActiveScaffold components.
-   **Improved Plugin & Bridge Support:** Better integration with external gems like TinyMCE, ActiveStorage, CarrierWave, Dragonfly, Paperclip and RecordSelect.
-   **Bug Fixes & Stability Improvements:** Addressed multiple issues reported by the community to enhance reliability and ease of use.

------------------------------------------------------------------------

### **How to Upgrade?**

If you’re using an older version of ActiveScaffold, upgrading is simple. Add or update the gem in your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold', '~> 4.0'
{%- endhighlight -%}

Then, run:

{% highlight shell -%}
bundle update active_scaffold
{%- endhighlight -%}

Add `active_scaffold/manifest.js` to `app/assets/config/manifest.js` to prevent issues with assets.

------------------------------------------------------------------------

### Breaking Changes

Support for rails 5.2 and 6.0, and ruby 2.x, has been removed.

Changing column settings on a request has changed, it must use `active_scaffold_config.columns.override(:name)` at least the first time. After calling `columns.override(:name)`, calling it again or calling `columns[:name]` will return the overrided column. It also supports a block. See [Per Request Configuration](https://github.com/activescaffold/active_scaffold/wiki/Per-Request-Configuration) for examples and more comprehensive explanation.

Changing columns for an action (e.g. add or exclude) on a request must use active\_scaffold\_config.actions.override\_columns, the first time, or use assignment with the whole list of columns.

If you have a `_form_association_record` partial view overrided, use `record` local variable instead of `form_association_record`.

If you have code rendering `form_association_record` partial, then pass `record` local variable instead of using `:object` option, or use `as: :record` if you're using render with `:collection` argument.

------------------------------------------------------------------------

### **What’s Next?**

This release is a major step forward, but we’re not stopping here! Future updates will continue to improve performance, add new features, and enhance integration with modern Rails workflows. If you have feedback or feature requests, we welcome contributions on [GitHub](https://github.com/activescaffold/active_scaffold).

------------------------------------------------------------------------

### **Try It Now!**

Download **ActiveScaffold 4.0** today and experience the improvements firsthand. Stay tuned for more updates and upcoming tutorials on how to make the most of the new features.

------------------------------------------------------------------------

🚀 **Happy coding with ActiveScaffold!**
