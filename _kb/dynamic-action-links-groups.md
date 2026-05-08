---
title: "Dynamic action links groups"
category: "Advanced"
---

It's possible to add an action which display dynamically a group of actions, adding a controller action which builds the action links group and displays it with ActiveScaffold.display_dynamic_action_group

{% highlight ruby -%}
class TeamsController < ApplicationController
  active_scaffold :team do |conf|
    ....
    conf.action_links.member.add 'report', :position => false
    ....
  end

  def report
    @record = find_if_allowed(params[:id], :read)
  end
end
{%- endhighlight %}

{% highlight erb -%}
# report.js.erb
<%
  links = @record.report_types.map do |report_type|
    link_to(report_type.to_label, report_path(@record, report_type))
  end
%>
<%= display_dynamic_action_group active_scaffold_config.action_links[:report], links, @record, :class => 'report_submenu' %>
{%- endhighlight %}
