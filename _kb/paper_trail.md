---
title: "paper_trail"
category: "Integrations"
---

[PaperTrail](https://github.com/airblade/paper_trail) bridge adds:

- a collection link to deleted action which display deleted_records
- a member link to PaperTrail::VersionsController which display changes for current record. PaperTrail::VersionsController must be added, not included with ActiveScaffold.

A PaperTrail::VersionsController, which list versions and uses show action to display old record, could be like this:

{% highlight ruby -%}
#app/controllers/paper_trail/versions_controller.rb 
class PaperTrail::VersionsController < ApplicationController
  active_scaffold PaperTrail::Version do |config|
    config.actions = [:list, :show, :nested]
  end

  protected
  def do_show
    super
    @record = @record.reify
  end

  def show_authorized?(record = nil)
    record.try(:event) != 'create' && super
  end
end

#app/views/paper_trail/versions/_show.html.erb 
<% extend "#{@record.class.name.pluralize}Helper".constantize rescue nil %>
<%= render :super %>

#config/routes.rb
  namespace :paper_trail do
     resources :versions, concerns: :active_scaffold
  end
{%- endhighlight %}
For controllers that use paper_trail, 
for a collection link:  
{% highlight ruby -%}
  conf.actions = [... :deleted_records ...]
{%- endhighlight %}
for a member_link
{% highlight ruby -%}
  conf.nested.add_link :versions
{%- endhighlight %}
