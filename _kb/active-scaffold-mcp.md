---
title: "Getting Started with ActiveScaffold MCP"
date: "2026-10-21 11:14:00.000000000 +02:00"
category: "MCP"
---

ActiveScaffold MCP generates ActionMCP tools from ActiveScaffold controller configuration. Version 0.1.1 provides read-only list and show tools and exposes nothing until the application opts in.

## Requirements and installation

ActiveScaffold MCP 0.1.1 requires Ruby 3.4 or newer, Rails 8.1 or newer, Active Scaffold 4.4 or newer, and ActionMCP 0.200 or newer.

Add the gem to your application and install it:

{% highlight ruby -%}
gem "active_scaffold_mcp", "~> 0.1.1"
{%- endhighlight %}

{% highlight shell -%}
bundle install
{%- endhighlight %}

Configure and mount the ActionMCP server according to the [ActionMCP documentation](https://github.com/seuros/action_mcp). ActiveScaffold MCP adds the `:mcp` ActiveScaffold action, which builds configured tools when a controller is loaded.

## Expose list and show tools

Use `config.mcp.expose` inside a controller's `active_scaffold` block:

{% highlight ruby -%}
class TicketsController < ApplicationController
  active_scaffold :ticket do |config|
    config.mcp.name = :support_tickets
    config.mcp.label = "Support tickets"

    config.mcp.expose :list,
                      description: "Find support tickets by status or queue.",
                      columns: %i[id subject status customer_id],
                      filter_columns: {
                        id: %i[equal in],
                        status: %i[equal in]
                      }

    config.mcp.expose :show,
                      columns: %i[id subject status description],
                      lookup_columns: %i[case_number]
  end
end
{%- endhighlight %}

This creates `list_support_tickets` and `show_support_ticket`.

`config.mcp.name` is the stable resource name shared by generated actions and defaults to the model's route key. `config.mcp.label` is the human-readable resource label and defaults to ActiveScaffold's plural label.

An action can override both values. An action-level `name` is the complete tool identifier:

{% highlight ruby -%}
config.mcp.expose :list,
                  name: :search_support_tickets,
                  label: "Searchable support tickets"
{%- endhighlight %}

The title is display metadata for MCP clients. The description tells a model when and how to use the tool. ActiveScaffold MCP generates a description from the available filters and options unless an explicit `description` is supplied.

The hash form is also supported:

{% highlight ruby -%}
config.mcp.actions = {
  list: {
    columns: %i[id subject status],
    filter_columns: {status: %i[equal in]}
  },
  show: {
    columns: %i[id subject description],
    lookup_columns: %i[case_number]
  }
}
{%- endhighlight %}

`config.mcp.actions = :all` asks the generator factory to expose every enabled ActiveScaffold action. Version 0.1.1 includes generators only for `list` and `show`; if another action is enabled, register a compatible generator before using `:all` or tool generation will raise `ActiveScaffold::MCP::GeneratorFactory::GeneratorNotFound`. Explicit exposure is usually easier to review.

## Configure global defaults

Common actions and settings can be exposed for every ActiveScaffold controller:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.mcp.filter_column_sets = {
    foreign_keys: :in,
    dates: :range,
    timestamps: :range
  }

  config.mcp.expose :list do |action|
    action.filter_columns = {id: %i[equal in]}
  end
  config.mcp.expose :show
end
{%- endhighlight %}

`filter_column_sets` adds filters to every exposed list action unless that action supplies its own `filter_column_sets`. The available sets are:

- `foreign_keys`: columns whose names end in `_id`; a polymorphic association also exposes its corresponding type column;
- `dates`: columns with the `date` type; and
- `timestamps`: `datetime`, `timestamp`, and `timestamptz` columns.

Each set must specify its operators. Common choices are `:in` for foreign keys and `:range` for dates and timestamps. `:range` is an alias for `:between`; all supported operators and the generated argument names are documented in [Read Tools: List and Show](/doc/active-scaffold-mcp-read-tools/#column-filters).

All settings passed to `config.mcp.expose` are also global action defaults. A list default can set `columns`, `filter_columns`, `filter_column_sets`, `filters`, and `search`. A show default can set `columns` and `lookup_columns`. Both actions accept the common `name`, `label`, `description`, `modules`, `presenter`, and `presenter_modules` settings. Controller configuration can add or override these defaults.

The remaining MCP-wide defaults are intended primarily for application integration and extension:

| Setting | Purpose |
| --- | --- |
| `config.mcp.actions` | Sets all globally exposed actions at once. `expose` is usually clearer and supports a configuration block. |
| `config.mcp.base_tool` | Selects the superclass for generated tools. It defaults to `ApplicationMCPTool` when defined, otherwise `ActionMCP::Tool`. |
| `config.mcp.settings_validator` | Selects the validator for action settings, including settings introduced by custom actions. |
| `config.mcp.tool_generator` | Selects the generator factory used to build tools for exposed actions. |

See [Authentication and Tool Discovery](/doc/active-scaffold-mcp-authentication/#select-the-base-tool-explicitly) for `base_tool`, and [Extending ActiveScaffold MCP](/doc/extending-active-scaffold-mcp/) for validators and generators.

Use global settings only for actions, filters, and fields that are safe and meaningful across every scaffold. In particular, globally configured `columns`, `lookup_columns`, names, or behavior modules rarely fit unrelated models. Keep business-specific filters, sensitive columns, descriptions, and behavior in the controller that owns them.

## Reuse query and authorization behavior

Generated tools are not instances of the Rails controller. Move ActiveScaffold hooks needed by both HTTP and MCP execution into a module, include it in the controller, and configure the same module for the MCP action:

{% highlight ruby -%}
module TicketListBehavior
  def list_authorized?
    current_user.has_right?("tickets", "index")
  end

  def beginning_of_chain
    super.where(account_id: current_user.account_id)
  end
end

class TicketsController < ApplicationController
  active_scaffold :ticket do |config|
    config.custom_modules << TicketListBehavior
    config.mcp.expose :list, modules: TicketListBehavior
  end
end
{%- endhighlight %}

Configured modules are included after the corresponding ActiveScaffold action module. They can override hooks such as `list_authorized?`, `beginning_of_chain`, `conditions_for_collection`, and named-filter security methods. Keep request- and response-specific controller code out of shared modules.

Use `modules` for query and authorization behavior. Use `presenter_modules` only for result presentation.

## Inspect generated tools

List every registered ActionMCP tool:

{% highlight shell -%}
bin/rails action_mcp:list_tools
{%- endhighlight %}

This task reads the complete registry. It does not apply profiles or per-user discovery authorization.

Inspect the generated input schemas as JSON:

{% highlight shell -%}
bin/rails action_mcp:apps:schema |
  jq '.tools[] | select(.name == "list_support_tickets")'
{%- endhighlight %}

For an authorization-aware view of a profile, see [Authentication, Authorization, and Tool Discovery](/doc/active-scaffold-mcp-authentication/).

## Continue reading

- [Read Tools: List, Show, and Output](/doc/active-scaffold-mcp-read-tools/)
- [Authentication, Authorization, and Tool Discovery](/doc/active-scaffold-mcp-authentication/)
- [Extending ActiveScaffold MCP](/doc/extending-active-scaffold-mcp/)
