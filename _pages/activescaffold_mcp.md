---
layout: page
title: ActiveScaffold MCP
date: 2026-10-21 11:14:00.000000000 +02:00
permalink: "/plugins/activescaffoldmcp/"
parent: Plugins
nav_order: 9
hero_heading: MCP tools from ActiveScaffold configuration
hero_lead: Give MCP clients controlled, read-only access to your ActiveScaffold resources
---

ActiveScaffold MCP generates [ActionMCP](https://github.com/seuros/action_mcp) tools from the configuration already defined in ActiveScaffold controllers. Version 0.1.1 supports read-only list and show tools, with explicit control over the actions, columns, filters, and record lookups exposed to MCP clients.

### Requirements

- Ruby 3.4 or newer
- Rails 8.1 or newer
- Active Scaffold 4.4 or newer
- ActionMCP 0.200 or newer

### Installation

Add the gem to your `Gemfile`:

{% highlight ruby -%}
gem "active_scaffold_mcp", "~> 0.1.1"
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

Configure ActionMCP for your application, then select the ActiveScaffold actions that may become tools. Nothing is exposed by default:

{% highlight ruby -%}
class TicketsController < ApplicationController
  active_scaffold :ticket do |config|
    config.mcp.name = :support_tickets
    config.mcp.label = "Support tickets"

    config.mcp.expose :list,
                      columns: %i[id subject status customer_id],
                      filter_columns: {
                        id: %i[equal in],
                        status: %i[equal in]
                      },
                      filters: %i[open overdue]

    config.mcp.expose :show,
                      columns: %i[id subject status description],
                      lookup_columns: %i[case_number]
  end
end
{%- endhighlight %}

This configuration generates tools such as `list_support_tickets` and `show_support_ticket`. The list tool reuses ActiveScaffold's query, search, sorting, pagination, named-filter, and authorization behavior. The show tool can find one authorized record by its primary key or an explicitly configured alternative identifier.

### Configure defaults for all controllers

Common actions can be exposed for every ActiveScaffold controller through `ActiveScaffold.defaults`. Controller-specific configuration can still add or override columns, filters, descriptions, and other settings:

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

This makes every exposed list filterable by its `*_id` columns and by ranges of date and timestamp columns. Each set requires an explicit operator: the gem does not assume whether an application wants equality, membership, or ranges. A controller can override `filter_column_sets` for its own list action.

Defaults are useful for establishing a consistent baseline, but only expose actions and fields that are safe across every scaffold. Keep business-specific or sensitive configuration in the relevant controller. The [global defaults guide](/doc/active-scaffold-mcp/#configure-global-defaults) lists the other application-wide settings, while [Read Tools: List and Show](/doc/active-scaffold-mcp-read-tools/#column-filters) explains filter sets and operators.

### Before exposing an existing scaffold

MCP tools are not Rails controller instances. If an existing scaffold relies on controller hook overrides for authorization or query behavior—such as `list_authorized?`, `show_authorized?`, `beginning_of_chain`, or `conditions_for_collection`—move the reusable hooks into a module and expose the action with that module:

```ruby
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
```

This keeps the same behavior available to both the controller and the generated tool. See [Reuse query and authorization behavior](/doc/active-scaffold-mcp/#reuse-query-and-authorization-behavior) for the complete pattern.

Virtual columns need similar attention. MCP deliberately does not call ActiveScaffold view-helper overrides such as `status_badge_column(record, column)`, because those methods often return HTML. A virtual column implemented only in a helper is therefore omitted from `list` and `show` output. To expose it, move its presentation-independent value into a presenter module:

```ruby
module TicketMCPPresentation
  def status_badge_column(record, _column)
    record.status
  end
end

config.mcp.expose :show,
                  columns: %i[id status_badge],
                  presenter_modules: TicketMCPPresentation
```

Presenter methods should return structured, non-HTML values. See [Customize presentation](/doc/active-scaffold-mcp-read-tools/#customize-presentation) for list and show configuration details.

### Designed for controlled exposure

ActiveScaffold MCP does not publish every scaffold automatically. Applications choose the actions and data appropriate for agent access. Generated tools apply ActiveScaffold's column and record authorization, action-specific authorization such as `list_authorized?`, and an optional application-level authorization hook during both discovery and execution.

Version 0.1.1 is intentionally read-only. It generates list and show tools. Support for write actions—including create, update, delete, and applicable custom actions—is planned for later releases.

### Documentation

The MCP documentation is organized by task:

- [Getting Started with ActiveScaffold MCP](/doc/active-scaffold-mcp/)
- [Read Tools: List, Show, and Output](/doc/active-scaffold-mcp-read-tools/)
- [Authentication, Authorization, and Tool Discovery](/doc/active-scaffold-mcp-authentication/)
- [Extending ActiveScaffold MCP](/doc/extending-active-scaffold-mcp/)

[Get ActiveScaffold MCP on RubyGems](https://rubygems.org/gems/active_scaffold_mcp){: .btn .btn-primary}
[View the source on GitHub](https://github.com/activescaffold/active_scaffold_mcp){: .btn}
{: .text-center}
