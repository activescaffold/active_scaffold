---
title: "Announcing ActiveScaffold MCP 0.1.1"
date: "2026-10-21 11:14:00.000000000 +02:00"
categories:
- Releases
---

**ActiveScaffold MCP 0.1.1 is now available.** The new plugin turns selected ActiveScaffold list and show configuration into read-only [Model Context Protocol](https://modelcontextprotocol.io/) tools through [ActionMCP](https://github.com/seuros/action_mcp).

If an application already describes its resources, columns, filters, sorting, labels, and authorization with ActiveScaffold, it should not need a second independent data-access layer just to make those resources available to an MCP client. ActiveScaffold MCP reuses that configuration while keeping exposure explicit.

------------------------------------------------------------------------

## Start with an explicit MCP contract

No controller action is exposed by default. Choose the actions and data that make sense for agent access:

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

This example creates `list_support_tickets` and `show_support_ticket`. The list tool supports bounded pagination together with the selected column filters and named ActiveScaffold filters. When the scaffold has search enabled, the tool can also expose full-text search across its configured search columns.

The show tool uses the model primary key by default. Explicit `lookup_columns` let a client retrieve a record with an application identifier such as a case number while still requiring the lookup to resolve to exactly one authorized record.

------------------------------------------------------------------------

## Expose common actions across controllers

Applications that want the same MCP baseline on every scaffold can configure it once with `ActiveScaffold.defaults`:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.mcp.expose :list do |action|
    action.filter_columns = {id: %i[equal in]}
  end
  config.mcp.expose :show
end
{%- endhighlight %}

Every ActiveScaffold controller inherits these MCP defaults. A controller can then add or override settings for its own resource. Global defaults are best for actions and fields that are safe everywhere; business-specific filters, columns, and descriptions should remain in the controller that owns them.

------------------------------------------------------------------------

## Reuse ActiveScaffold behavior

Generated list tools reuse ActiveScaffold's query, filtering, searching, sorting, pagination, and authorization behavior. Results are structured data rather than rendered HTML, with predictable representations for singular and collection associations.

ActiveScaffold Config List is supported too. A generated list tool can accept configured named views, and applications with user-saved views get a companion tool that lists the views available to the current user.

Applications can share query and authorization hooks between their controller and generated tools through modules. Presentation-specific modules or a custom presenter can provide computed, non-HTML values without coupling MCP output to view helpers.

------------------------------------------------------------------------

## Authorization at discovery and execution

ActiveScaffold MCP applies ActiveScaffold's action, column, and record authorization while it builds results. An optional authorization hook on the application's ActionMCP base tool can also filter which tools a user discovers, and the same hook is checked again before execution.

That layered approach is deliberate: MCP exposure is an application interface, not an automatic mirror of every controller. Version 0.1.1 focuses on read-only list and show operations.

------------------------------------------------------------------------

## Write actions are coming later

Support for write actions—including create, update, delete, and applicable custom ActiveScaffold actions—is planned for later releases. Starting with read-only tools gives the integration a clear foundation for discovery, schemas, filtering, serialization, and authorization before MCP clients are allowed to change application data.

------------------------------------------------------------------------

## Install version 0.1.1

ActiveScaffold MCP 0.1.1 requires Ruby 3.4+, Rails 8.1+, Active Scaffold 4.4+, and ActionMCP 0.200+.

{% highlight ruby -%}
gem "active_scaffold_mcp", "~> 0.1.1"
{%- endhighlight %}

Then run `bundle install`, configure ActionMCP, and opt in the ActiveScaffold actions you want to expose.

Visit the [ActiveScaffold MCP plugin page](/plugins/activescaffoldmcp/) for an overview, then browse the [MCP documentation](/doc/#mcp) for setup, read tools, authentication and discovery filtering, and extension points.

[Get ActiveScaffold MCP 0.1.1 on RubyGems](https://rubygems.org/gems/active_scaffold_mcp){: .btn .btn-primary}
[View the source on GitHub](https://github.com/activescaffold/active_scaffold_mcp){: .btn}
{: .text-center}

🚀 **Happy scaffolding with ActiveScaffold!**
