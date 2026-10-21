---
title: "Extending ActiveScaffold MCP"
date: "2026-10-21 11:14:00.000000000 +02:00"
category: "MCP"
---

ActiveScaffold MCP 0.1.1 includes generators for read-only list and show tools. Its settings validator, generator factory, tool base class, behavior modules, and presenters provide extension points for application-specific integrations.

Start with [Getting Started with ActiveScaffold MCP](/doc/active-scaffold-mcp/) before adding custom generators.

## Extend settings validation

The built-in list and show actions validate their supported settings. Unknown custom actions accept settings by default so an application-provided generator can define its own contract.

To validate custom settings, subclass the default validator and implement a matching `valid_settings_for_<action>?` method:

{% highlight ruby -%}
class ApplicationMCPSettingsValidator < ActiveScaffold::MCP::SettingsValidator
  private

  def valid_settings_for_publish?(setting, value)
    setting == :notify && [true, false].include?(value)
  end
end

ActiveScaffold.defaults do |config|
  config.mcp.settings_validator = ApplicationMCPSettingsValidator
end
{%- endhighlight %}

Configure the validator before controllers build their generated tools.

## Register tool generators

`config.mcp.tool_generator` defaults to an `ActiveScaffold::MCP::GeneratorFactory`. The factory supports three registration styles:

- `register` selects a generator for exact action names.
- `register_default` selects a generator from standard action metadata such as CRUD type and whether the action has columns.
- `register_custom` selects a generator from custom-action metadata such as submit method, columns, and destructive behavior.

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  factory = config.mcp.tool_generator

  factory.register(ShowToolGenerator, actions: %i[show details])

  factory.register_default(
    FormToolGenerator,
    crud_type: :create,
    columns: true
  )

  factory.register_custom(
    DestructiveActionToolGenerator,
    submit_method: :post,
    columns: false,
    destructive: true
  )
end
{%- endhighlight %}

More-specific metadata rules take precedence over less-specific ones. When rules have equal specificity, the most recently registered matching rule wins.

## Implement a generator

An action generator implements `generate_tool_for`:

{% highlight ruby -%}
def self.generate_tool_for(
  controller_class:,
  action_name:,
  action_config:,
  mcp_config:,
  settings:
)
  # Build and return one or more ActionMCP tool classes.
end
{%- endhighlight %}

It may return one tool class, an array of tool classes, or `nil`. The factory's public entry point is `generate_tools_for`.

The built-in `ListToolGenerator` and `ShowToolGenerator` are registered by exact action name. `config.mcp.actions = :all` still requires the factory to find a generator for every enabled action; an unsupported action raises `ActiveScaffold::MCP::GeneratorFactory::GeneratorNotFound`.

## Extend tool behavior

Use an action's `modules` setting for query, execution, and authorization behavior:

{% highlight ruby -%}
config.mcp.expose :list, modules: TicketListBehavior
{%- endhighlight %}

Configured modules are included after the ActiveScaffold action module, so they can override its hooks. Keep HTTP-only controller methods out of shared modules because generated tools are not Rails controller instances.

Use `presenter_modules` or a custom `presenter` for serialization only. The complete presenter contract and examples are in [Read Tools: List, Show, and Output](/doc/active-scaffold-mcp-read-tools/#customize-presentation).

Use an application base tool for behavior shared by every generated tool. Authentication and discovery filtering through the base tool are covered in [Authentication, Authorization, and Tool Discovery](/doc/active-scaffold-mcp-authentication/).

## Generated-tool lifecycle

The MCP action generates tools when its ActiveScaffold controller is loaded. ActiveScaffold MCP tracks the controller names and generated classes. In a reloading Rails environment, its engine removes stale generated classes from the ActionMCP registry and rebuilds them during `to_prepare`.

Configure global validators, factories, and the base tool before controllers are loaded so generated classes use the intended extension points.

## Write generators and future releases

Support for built-in write actions—including create, update, delete, and applicable custom ActiveScaffold actions—is planned for later releases.

An application can register its own generator today, but a write integration is responsible for:

- validating its input schema and rejecting ambiguous requests;
- applying discovery and execution authorization;
- preserving ActiveScaffold and model-level authorization;
- requesting consent for destructive or consequential operations;
- defining transaction, validation, and callback behavior; and
- returning a stable, structured result contract.

Treat every generated tool as a public application interface and test it with the same care as an HTTP API.

See the [ActiveScaffold MCP source repository](https://github.com/activescaffold/active_scaffold_mcp) for implementation details and updates.

