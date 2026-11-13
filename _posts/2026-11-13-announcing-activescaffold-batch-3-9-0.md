---
title: "Announcing ActiveScaffold Batch 3.9.0: Safer Direct Updates and Modern Compatibility"
date: "2026-11-13 21:10:00.000000000 +01:00"
categories:
- Releases
---

**ActiveScaffold Batch 3.9.0** is now available. This release improves the behavior of direct SQL batch updates, reports Active Record errors from Batch Create more clearly, and modernizes the plugin for current Ruby, Rails, and ActiveScaffold applications.

------------------------------------------------------------------------

## Keep timestamps current with `update_all`

Batch Update's `:update_all` mode updates many records in one SQL statement. It is useful for large batches where model callbacks, validations, and per-record processing are not required:

{% highlight ruby -%}
config.batch_update.process_mode = :update_all
{%- endhighlight %}

Active Record does not update timestamp columns automatically when `update_all` is used. Batch 3.9 now adds the model's update timestamp to the same SQL statement by default. It uses Active Record's timestamp configuration, so it supports `updated_at`, `updated_on`, and attribute aliases without requiring a hard-coded column name.

If an application manages timestamps itself, the new behavior can be disabled for a scaffold:

{% highlight ruby -%}
config.batch_update.update_timestamps = false
{%- endhighlight %}

An update timestamp explicitly included in the batch is preserved instead of being replaced by the automatic value.

The other characteristics of `:update_all` are unchanged: it remains a direct database operation and does not run model validations or callbacks. Use the default `:update` mode when those hooks are required.

------------------------------------------------------------------------

## Report Batch Create persistence errors

Batch Create now handles errors raised by Active Record during persistence without silently discarding them. When the model has no validation errors to display, the exception message is added as a base error so the failed record can be reported in the Batch form.

The transaction modes continue to work as before:

- `true` saves the complete batch in one transaction and rolls it back if a record fails.
- `false` keeps successful records when another record fails.
- `:validate_first` validates every record before saving any of them.

------------------------------------------------------------------------

## Safer translated markup

The localized “add records” text contains the rendered row-count input. Batch 3.9 moves that message to an explicit `.html` translation and relies on ActiveScaffold's HTML translation support instead of marking the complete translated string as safe in the view.

This preserves the form control while ensuring ordinary interpolated values are escaped. The JavaScript response templates and form helpers have received the same output-safety cleanup.

------------------------------------------------------------------------

## Tested on the modern stack

The plugin now requires:

- Ruby 3.2 or newer.
- ActiveScaffold 4.4.6 or newer.

ActiveScaffold 4.4.6 provides the explicit HTML translation behavior used by the Batch views. The release also adds automated coverage for Batch Create, Update, and Destroy, their configuration, and the form helpers. GitHub Actions now runs both the test suite and RuboCop for every change.

------------------------------------------------------------------------

## Upgrade

Update your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4", ">= 4.4.6"
gem "active_scaffold_batch", "~> 3.9"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle update active_scaffold active_scaffold_batch
{%- endhighlight %}

Visit the [ActiveScaffold Batch plugin page](/plugins/activescaffoldbatch/) for configuration examples, transaction modes, action scopes, and UI adapter integration.

------------------------------------------------------------------------

🚀 **Happy scaffolding with ActiveScaffold!**
