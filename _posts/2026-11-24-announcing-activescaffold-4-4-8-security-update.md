---
title: "ActiveScaffold 4.4.8: Important Security Fixes"
date: "2026-11-24 14:05:13 +01:00"
categories:
- Releases
---

**ActiveScaffold 4.4.8 is now available.** This patch release gets a separate announcement because it includes several security fixes affecting request parameters, record authorization, and JSON/XML association exports. Applications using ActiveScaffold 4.4 should upgrade and review the configuration changes below.

**For API association exports, upgrading is only the first step:** 4.4.8 preserves the legacy output by default for compatibility. Set `unsafe_api_associations = false` to enable the restricted output and its associated-record authorization checks.

## Upgrade to 4.4.8

Update your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold", "~> 4.4.8"
{%- endhighlight %}

Then update the gem and commit the resulting lockfile:

{% highlight shell -%}
bundle update active_scaffold
{%- endhighlight %}

ActiveScaffold 4.4 requires **Ruby 3.2 or newer and Rails 7.2 or newer**.

## What this release fixes

Several paths now validate request parameters before using them in sensitive operations:

- **Embedded conditions and constraints:** controller-bound signatures authenticate application-generated values before they affect database queries or record attributes. Unsigned or altered values are rejected.
- **Return destinations:** signatures authenticate `return_to` values before they appear in Close and Cancel links or redirects. Applications retain control over whether redirects to external hosts are allowed.
- **Inline editing:** the requested column must have inline editing enabled before its editor is rendered or an update override is invoked.
- **Existing association records:** add-existing and subform actions check read authorization on selected records. The `associated_record_scope` hook allows applications to restrict which records can be selected.
- **Tabbed subforms:** application-generated tab selections are signed, grouping fields are validated against configuration, and changing an existing record's grouping requires update authorization. Association changes are staged until the parent form is saved.
- **Grouped and date searches:** grouping values must match configured options, and date trend units must be supported durations. Applications extending the unit dropdown can also override `valid_datetime_trend_unit?`.

The release also introduces restricted API association exports, with a compatibility path for existing clients.

## Enable restricted API association exports

Legacy association serialization can expose every database attribute of a related record, including fields hidden by that record's scaffold. Hiding an attribute from an HTML screen does not make it private in JSON or XML.

Enable the restricted output globally in an initializer, before scaffold controllers load:

{% highlight ruby -%}
ActiveScaffold::Config::Core.unsafe_api_associations = false
{%- endhighlight %}

Or enable it for an individual scaffold:

{% highlight ruby -%}
active_scaffold do |config|
  config.unsafe_api_associations = false
end
{%- endhighlight %}

With this setting, each readable associated record is represented by its primary key and `to_label`. For a model whose primary key is `id`, a singular association looks like:

{% highlight json -%}
{
  "company": {
    "id": 42,
    "to_label": "Example company"
  }
}
{%- endhighlight %}

Unreadable singular records become `null` in JSON, and unreadable records are omitted from collections. XML uses the equivalent hash and array representation. Associations are not expanded recursively by default, and the associated scaffold's configuration is not loaded.

The 4.4.x setting has three states:

| Value | Behavior |
| --- | --- |
| `nil` (default) | Retains legacy full-attribute exports and emits a deprecation warning when associations are exported. |
| `false` | Enables restricted exports with associated-record read authorization. |
| `true` | Explicitly retains unsafe legacy exports without the warning. |

**Setting `true` only suppresses the warning; it does not address the unsafe behavior.** Test API clients with `false` and explicitly select any additional data they need.

### Customize additional association data

Override `api_association_options(column, record)` to return options for Rails' `serializable_hash`. A fixed selection can look like this:

{% highlight ruby -%}
protected

def api_association_options(column, record)
  if column.name == :company
    {only: [record.class.primary_key, :name], methods: [:to_label]}
  else
    super
  end
end
{%- endhighlight %}

The associated record's read permission is checked automatically. Column permissions for fields returned by this hook are the application's responsibility; filter them with `authorized_for?` when needed. Explicit nested `include:` options use normal Rails serialization, so applications must also authorize the nested records and fields they request.

The [API association export guide](/doc/api-association-exports/) includes examples of column authorization, nested includes, and the complete migration behavior.

## Review custom URLs and hardening settings

ActiveScaffold's built-in URL generators sign the values they construct. If your application builds embedded scaffold URLs, return destinations, or tab-selection links itself, review those overrides after upgrading. The [embedded scaffold guide](/doc/embedded-scaffolds/) and [security reference](/doc/security/#signed-return-destinations) describe the signing helpers. Use them with trusted application-defined values; do not sign unverified incoming request parameters.

Two additional settings let applications reduce the data and formats exposed by their scaffolds:

- `conditions_from_params_allowed_columns` and `conditions_from_params_excluded_columns` control which database columns can be used as top-level URL filters. An empty allowed list disables this filtering; exclusions take precedence over allowed entries.
- `default_formats` can narrow the default response formats to those an application uses, such as HTML and JavaScript. Formats explicitly added through core or action configuration must be reviewed too.

These settings retain compatible defaults. See [API: Core](/doc/api-core/) to configure them for your application.

## Prepare for 4.5

ActiveScaffold 4.5 will remove the built-in legacy association serialization mode and the `unsafe_api_associations` setting. The setting will be removed entirely, rather than retained as a no-op: remove all assignments to it, including assignments to `false`, when upgrading.

The default in 4.5 will be restricted association output. The `api_association_options` hook will remain available, and applications can deliberately broaden the output through it while taking responsibility for the fields and nested records they expose.

Adopting `unsafe_api_associations = false` on 4.4.8 lets applications test their API contracts and migrate before that upgrade.

Download [ActiveScaffold 4.4.8 on RubyGems](https://rubygems.org/gems/active_scaffold/versions/4.4.8) and read the [full changelog](https://github.com/activescaffold/active_scaffold/blob/v4.4.8/CHANGELOG.rdoc).
