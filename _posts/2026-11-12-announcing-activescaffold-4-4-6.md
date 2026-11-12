---
title: "ActiveScaffold 4.4.6: Prepare for CSP and ActiveScaffold 4.5"
date: "2026-11-12 18:45:00.000000000 +01:00"
categories:
- Releases
---

**ActiveScaffold 4.4.6** is now available. This release provides a migration path toward a strict Content Security Policy (CSP), adds safer handling for iframe responses, and introduces compatibility features that applications can adopt before upgrading to ActiveScaffold 4.5.

------------------------------------------------------------------------

## Adopt a strict CSP without a big-bang migration

Older ActiveScaffold configuration allowed JavaScript source to be stored in datepicker and TinyMCE settings. Evaluating that source requires `'unsafe-eval'` in the CSP `script-src` directive.

ActiveScaffold 4.4.6 introduces named callback registries so applications can move that code into ordinary JavaScript assets:

{% highlight javascript -%}
ActiveScaffold.datepickerCallbacks.availableDate = function(date) {
  return [date.getDay() !== 0, ""];
};

ActiveScaffold.tinymceCallbacks.configureEditor = function(editor) {
  editor.on("init", function() {
    // Application-specific editor setup
  });
};
{%- endhighlight %}

Refer to each callback by name from ActiveScaffold configuration:

{% highlight ruby -%}
config.columns[:starts_on].options[:data] = {
  beforeshowday: "availableDate"
}
{%- endhighlight %}

And from `config/tinymce.yml`:

{% highlight yaml -%}
default:
  setup: configureEditor
{%- endhighlight %}

Non-callback datepicker settings should use JSON-compatible values instead of JavaScript expressions. jQuery UI accepts a number of days from today and relative date strings, so `new Date` is not needed for common date limits:

{% highlight ruby -%}
# Before: these strings must be evaluated as JavaScript
config.columns[:starts_on].options[:data] = {
  mindate: "new Date()",
  maxdate: "new Date(new Date().setMonth(new Date().getMonth() + 1))"
}

# After: 0 means today and "+1m" means one month from today
config.columns[:starts_on].options[:data] = {
  mindate: 0,
  maxdate: "+1m"
}
{%- endhighlight %}

Fixed or server-calculated dates can be serialized as strings. Set `dateformat` to match their format:

{% highlight ruby -%}
config.columns[:starts_on].options[:data] = {
  dateformat: "yy-mm-dd",
  mindate: Date.current.iso8601,
  maxdate: 1.year.from_now.to_date.iso8601
}
{%- endhighlight %}

These values become ordinary numbers and strings in the input's data attributes, so the browser does not need to evaluate JavaScript to initialize the datepicker.

The old syntax still works in ActiveScaffold 4.4.6 and emits a browser deprecation warning when it is evaluated. This lets applications migrate one setting at a time. An application that has migrated all legacy settings can remove `'unsafe-eval'` from its CSP; an application that still uses them can keep `'unsafe-eval'` temporarily until its migration is complete.

ActiveScaffold 4.5 will remove the compatibility evaluator. Migrating while running 4.4.6 therefore makes the future upgrade smaller and easier to verify.

------------------------------------------------------------------------

## Safer iframe responses

`responds_to_parent` no longer evaluates a response with `window.eval`. It now creates a script in the parent document, copies the nonce from an existing parent script when available, executes the response in the parent document, and removes the temporary element.

This fixes iframe-targeted create and update responses under a nonce-based CSP and removes an unconditional dependency on JavaScript evaluation from that path.

------------------------------------------------------------------------

## RecordSelect callback integration

The add-existing subform integration now uses RecordSelect's named callback registry when the installed RecordSelect version provides it. Compatibility with older RecordSelect releases is retained, so applications can upgrade ActiveScaffold independently and then update RecordSelect when convenient.

------------------------------------------------------------------------

## Prepare HTML translations for 4.5

ActiveScaffold 4.4.6 adds explicit HTML translation keys. Move translations containing markup from a plain key to its `html` subkey:

{% highlight yaml -%}
# Before
active_scaffold:
  greeting: "<strong>Hello, %{name}</strong>"

# Compatible with 4.4.6 and ready for 4.5
active_scaffold:
  greeting:
    html: "<strong>Hello, %{name}</strong>"
{%- endhighlight %}

`as_(:greeting)` prefers `active_scaffold.greeting.html`. Rails' HTML translation behavior escapes unsafe interpolation values while preserving values that are already HTML safe.

For compatibility, 4.4.6 continues to treat legacy translations containing HTML as safe, but emits one deprecation warning per key and scope. ActiveScaffold 4.5 will no longer mark ordinary translations as HTML safe.

------------------------------------------------------------------------

## A practical 4.5 preparation checklist

While running ActiveScaffold 4.4.6:

1. Replace inline datepicker and TinyMCE JavaScript with named callbacks.
2. Replace JavaScript expressions in other datepicker settings with JSON-compatible values.
3. Remove `'unsafe-eval'` from a test or staging CSP and exercise forms, searches, datepickers, TinyMCE fields, and add-existing subforms.
4. Move translations containing markup under an `html` subkey.
5. Resolve the positional-boolean deprecation warnings introduced in ActiveScaffold 4.4.5.

Completing these steps in 4.4 keeps the compatibility paths available while changes are tested. ActiveScaffold 4.5 can then enforce the safer APIs without requiring all application changes during the framework upgrade itself.

------------------------------------------------------------------------

## Upgrade

Update your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4.6"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold
{%- endhighlight %}

ActiveScaffold 4.4 requires Ruby 3.2 or newer and Rails 7.2 or newer.

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
