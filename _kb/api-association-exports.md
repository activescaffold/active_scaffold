---
title: "API: Association Exports"
category: "API Reference"
---

## Scope and release status

This page describes association serialization in ActiveScaffold's JSON and XML responses. These changes are currently unreleased on `4-4-stable` and `master`, targeting the next 4.4.x update and 4.5 respectively.

Parent scaffold columns still require column read authorization. Association exports have a separate policy: the legacy output can expose all database attributes of related records, even when the related scaffold hides those attributes.

## Migrating on 4.4.x

The 4.4.x update preserves legacy association output by default for backwards compatibility. The global or per-controller `unsafe_api_associations` setting selects the behavior:

| Setting | Association output | Deprecation warning |
| --- | --- | --- |
| `nil` (default) | Legacy full-attribute serialization, without associated record or column read authorization | Once per response that exports associations |
| `true` | The same legacy unsafe serialization | Suppressed |
| `false` | Authorized associated records containing their primary key and `to_label` by default | None |

**Updating alone does not enable the safer association output on 4.4.x. Set `unsafe_api_associations = false` to enable it.** Setting `true` only suppresses the warning; it does not address the unsafe behavior.

To enable the safer output throughout the application, configure the global default in an initializer before scaffold controllers are loaded:

{% highlight ruby -%}
ActiveScaffold::Config::Core.unsafe_api_associations = false
{%- endhighlight %}

Or configure an individual scaffold:

{% highlight ruby -%}
active_scaffold do |config|
  config.unsafe_api_associations = false
end
{%- endhighlight %}

The deprecation warning explains that legacy serialization can expose all associated database attributes without checking associated record or column read authorization, and that this behavior and the compatibility setting will be removed in 4.5.

## Behavior in 4.5

The safer association output is always used. Both legacy full-attribute association serialization and the `unsafe_api_associations` setting are **removed**, rather than leaving an ignored compatibility setting.

Remove all global and controller assignments to `unsafe_api_associations` when upgrading to 4.5, including assignments to `false`. Keep any `api_association_options` overrides used to customize the new output.

## Default association output and authorization

Each readable associated record is exported as a hash containing its actual primary key and `to_label`. For a model using `id` as its primary key, a singular association looks like:

{% highlight json -%}
{
  "company": {
    "id": 42,
    "to_label": "Example company"
  }
}
{%- endhighlight %}

Collections contain an array of these hashes. A missing or unreadable singular record becomes `null` in JSON; unreadable records are omitted from collections. XML uses the equivalent hash and array representation.

ActiveScaffold checks `record.authorized_for?(crud_type: :read)` on associated records that support this method. A denied parent association column is not exported. The default primary key and label do not require individual column permission checks.

No associated scaffold configuration is loaded, and associations are not expanded recursively by default. If more data is needed, clients can request the related resource separately, or the application can customize its association output.

## api_association_options <small><em>override method</em></small> {#api_association_options}

Override this protected controller method on the scaffold producing the response. It receives the parent scaffold's association `column` and the associated `record`. Its default return value is:

{% highlight ruby -%}
def api_association_options(column, record)
  {only: [record.class.primary_key], methods: [:to_label]}
end
{%- endhighlight %}

The returned hash is passed directly to Rails' `serializable_hash`. Supported options include `only:`, `except:`, `methods:`, and `include:`. The option for nested associations is `include:` (singular), not `includes:`.

For example, export a fixed set of company attributes and its label:

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

### Authorizing additional fields

ActiveScaffold checks the associated record's read permission, but does not automatically check column permissions for the fields selected by this hook. The application is responsible for those checks when needed. Choose label and virtual methods that expose data appropriate for the API.

The following example retains the default primary key and label and filters additional fields using column read authorization:

{% highlight ruby -%}
protected

def api_association_options(column, record)
  options = super
  if column.name == :company
    columns = %i[name email].select do |name|
      record.authorized_for?(crud_type: :read, column: name)
    end
    options = options.merge(only: Array(options[:only]) + columns)
  end
  options
end
{%- endhighlight %}

### Explicit nested associations

Applications can include nested data using normal Rails serialization options:

{% highlight ruby -%}
def api_association_options(column, record)
  options = super
  if column.name == :company
    options = options.merge(include: {address: {only: [:city, :country]}})
  end
  options
end
{%- endhighlight %}

Nested includes use Rails' normal serialization. **The application must authorize every nested record and field it requests.** ActiveScaffold's associated-record check does not recursively authorize these explicit nested includes. An unrestricted `include:` can expose all database attributes of the nested records.

For JSON, the parent record uses `as_json` to preserve its model root, while associations use `serializable_hash`, matching Rails' own nested `include:` behavior. Enabling `include_root_in_json` on an associated model does not add a model root around each nested record.
