---
title: "ActiveScaffold MCP Authentication, Authorization, and Tool Discovery"
date: "2026-10-21 11:14:00.000000000 +02:00"
category: "MCP"
---

ActiveScaffold MCP uses the identity established by ActionMCP to filter tool discovery and authorize execution. The gem does not authenticate MCP clients itself: configure authentication in ActionMCP, then make the authenticated application user available as `ActionMCP::Current.user`.

## Authentication and current user

The configured ActionMCP authentication layer is responsible for validating the request or session and resolving the application's user. Generated ActiveScaffold tools obtain that identity through their `current_user` method, which delegates to `ActionMCP::Current.user`.

During execution, ActiveScaffold MCP temporarily exposes the same identity through `ActiveScaffold::Registry.current_user_proc`. ActiveScaffold action hooks, model authorization, named filters, named views, and shared behavior modules therefore see the MCP user as `current_user`.

Do not accept a user ID as a normal tool argument and treat it as authentication. The identity must come from the authenticated MCP session or request context.

## Filter tools during discovery

Use the application ActionMCP base tool to decide whether a generated ActiveScaffold tool is visible to the current user:

{% highlight ruby -%}
class ApplicationMCPTool < ActionMCP::Tool
  def self.active_scaffold_tool_authorized?(controller_class:, action_name:, user:)
    return false unless user

    user.has_right?(controller_class.controller_path, action_name)
  end
end
{%- endhighlight %}

The hook receives:

- `controller_class`: the ActiveScaffold controller that generated the tool;
- `action_name`: the source action, such as `:list` or `:show`; and
- `user`: `ActionMCP::Current.user` for the current discovery context.

Return `true` to keep the tool or `false` to remove it from the available tools. Keep this check inexpensive and independent of tool arguments because discovery has no call-specific arguments.

ActiveScaffold MCP prepends a filter to `ActionMCP::Configuration#filtered_tools`. ActionMCP first applies its active profile; ActiveScaffold MCP then calls the generated tool's authorization predicate. Manual tools and tools without this predicate remain unchanged.

In effect, discovery follows this sequence:

1. ActionMCP starts with the registered tools and applies the active profile.
2. Each generated ActiveScaffold tool calls `active_scaffold_tool_authorized?` with the current user.
3. Tools for which the hook returns `false` are omitted from `tools/list`.

The hook is optional. Without it, generated tools are not removed at this application-wide discovery layer, although normal execution authorization still applies.

## Discovery results are session-scoped

ActionMCP stores the filtered tool list in the MCP session. A client must reconnect after the user's permissions, roles, account scope, or applicable profile changes. Do not expect an existing session's discovered tool list to update automatically.

## Authorization is checked again during execution

Discovery filtering is not the only security boundary. Before `perform`, a generated tool calls the same application-level hook again inside the ActiveScaffold current-user context.

The concrete tool then applies action-specific authorization:

- list tools call `list_authorized?` and, when applicable, `search_authorized?`;
- show tools call `show_authorized?`;
- named filters and named views run their configured security methods; and
- output columns and records run ActiveScaffold's class-level and record-level `authorized_for?` checks.

Query scoping such as `beginning_of_chain` must also restrict records to the authenticated user's tenant or account. Put reusable hooks in a shared module as described in [Getting Started with ActiveScaffold MCP](/doc/active-scaffold-mcp/#reuse-query-and-authorization-behavior).

## Customize an execution denial

When an execution-level authorization check fails, the generated tool calls the private `unauthorized_tool!` method and stops before `perform`. By default it raises `ActiveScaffold::ActionNotAllowed`, which ActiveScaffold MCP reports as a tool error.

An application base tool may replace the fallback:

{% highlight ruby -%}
class ApplicationMCPTool < ActionMCP::Tool
  private

  def unauthorized_tool!
    raise ActiveScaffold::ActionNotAllowed,
          "You are not allowed to use #{self.class.tool_name}"
  end
end
{%- endhighlight %}

The application implementation should not call `super`. If it returns normally, the callback still stops before `perform`; the implementation should already have reported an appropriate error.

## Select the base tool explicitly

Generated tools inherit from `ApplicationMCPTool` when that constant exists, otherwise from `ActionMCP::Tool`. Configure the base class before controllers generate any tools when explicit selection is preferable:

{% highlight ruby -%}
ActiveScaffold.defaults do |config|
  config.mcp.base_tool = "ApplicationMCPTool"
end
{%- endhighlight %}

## Inspect discovery for a user

`action_mcp:list_tools` reads the complete registry, so it does not show per-user discovery filtering. Use ActionMCP's profile task for an authorization-aware result.

ActiveScaffold MCP accepts `MCP_USER=CLASS#ID` to establish `ActionMCP::Current.user` before that task runs:

{% highlight shell -%}
MCP_USER='User#123' bin/rails 'action_mcp:show_profile[primary]'
{%- endhighlight %}

Namespaced classes such as `Accounts::User#123` are supported. The class must exist and respond to `find`. Without `MCP_USER`, the task leaves `ActionMCP::Current.user` unset; a hook that requires a user will normally hide those generated tools.

`MCP_USER` is an inspection aid for the Rake task, not a production authentication mechanism.

See [Read Tools: List, Show, and Output](/doc/active-scaffold-mcp-read-tools/) for authorization behavior specific to list and show results.
