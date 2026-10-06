---
title: "Announcing ActiveScaffold Config List 4.1: Custom Views and UI Adapters"
date: "2026-10-06 15:00:00.000000000 +02:00"
categories:
- Releases
---

**ActiveScaffold Config List 4.1** is now available. This release makes named views more flexible with custom list partials, default view selection, and tooltips, while adopting the UI elements API introduced in ActiveScaffold 4.4.

------------------------------------------------------------------------

## Render a named view with its own partial

Named views are no longer limited to changing columns and sorting. A view can now render a custom partial, making it possible to present the same records as a compact list, calendar, cards, or another application-specific layout:

{% highlight ruby -%}
config.config_list.add_view :calendar do |view|
  view.label = "Calendar"
  view.view = "calendar_list"
end
{%- endhighlight %}

The partial receives the same assigns and helpers as the standard ActiveScaffold list. Views that use a custom partial do not need to define columns, although they may still do so when the partial uses the configured list columns.

------------------------------------------------------------------------

## Choose the initial named view

A controller can now select a named view when the request does not specify one:

{% highlight ruby -%}
config.config_list.default_view = :calendar
{%- endhighlight %}

An explicit empty `config_list_view` continues to select the ordinary configurable list, so users can still return to it from the view selector.

Applications can also control whether that ordinary, unnamed view appears in the selector:

{% highlight ruby -%}
config.config_list.unnamed_view_security_method = :unnamed_list_view_authorized?
{%- endhighlight %}

The configured controller method determines whether the choice is visible. Authorization for the underlying list action should still be enforced separately.

------------------------------------------------------------------------

## Add context with view tooltips

Controller-defined named views can include a tooltip. It is exposed consistently by the links, radio-button, and select-field selectors:

{% highlight ruby -%}
config.config_list.add_view :pending do |view|
  view.label = "Pending review"
  view.tooltip = "Records that still require approval"
  view.columns = [:name, :submitted_at, :reviewer]
end
{%- endhighlight %}

------------------------------------------------------------------------

## Style Config List with a UI framework adapter

Config List 4.1 uses ActiveScaffold 4.4's UI elements API throughout its view selector and configuration form. Bootstrap, Tailwind CSS, and other adapters can now customize tags and attributes without replacing the plugin's templates.

For example, an adapter can style the selector controls with the same registry used by ActiveScaffold itself:

{% highlight ruby -%}
ActiveScaffold.add_element_attributes :config_list_view_link,
                                      class: "dropdown-item"
ActiveScaffold.add_element_attributes :config_list_view_select,
                                      class: "form-select"
ActiveScaffold.add_element_attributes :config_list_view_radio,
                                      class: "form-check-input"
{%- endhighlight %}

The columns list, sorting controls, view-name field, and global and rename options also expose named UI elements for adapter customization.

------------------------------------------------------------------------

## Fixes and compatibility improvements

This release also:

- Prevents `config_list_view` from leaking into nested ActiveScaffold links.
- Keeps a selected named view available while rendering a custom list partial.
- Fixes Config List helpers when the plugin is installed but a controller does not enable the `config_list` action.
- Corrects configuration-form parameters and the reset URL for the ActiveScaffold 4.4 form helpers.

------------------------------------------------------------------------

## Upgrade

ActiveScaffold Config List 4.1 requires ActiveScaffold 4.4.0 or newer. Update your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4.0"
gem "active_scaffold_config_list", "~> 4.1"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold active_scaffold_config_list
{%- endhighlight %}

Read the [named views tutorial](/doc/config-list-named-views/) for the complete setup, or visit the [ActiveScaffold Config List plugin page](/plugins/activescaffoldconfiglist/).

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
