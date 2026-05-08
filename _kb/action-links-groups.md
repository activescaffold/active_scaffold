---
title: "Action links groups"
category: "Advanced"
---

If you want to add an action_link to your controller you do something like `conf.action_links << ….`. Internally, these are stored in an array. If list header is rendered all action_links of type 'collection' are selected and the same happens for type 'member' for each list row.

The grouping is achieved by changing the array to a tree structure. Leafs are representing action_links and nodes represent our groups. Two groups are automatically created: 'member' and 'collection'. 

Let s start with the first example. We would like to add all collection actions (create, search) to a group 'menu' for our teams controller.

{% highlight ruby -%}
class TeamsController < ApplicationController
  active_scaffold :team do |conf|
    ....
    conf.search.action_group = 'collection.menu' 
    conf.create.action_group = 'collection.menu' 
    ....
  end
end
{%- endhighlight %}

Now you should see a menu link at the top of your teams list view, which opens a "submenu" when hovering over it.

Another example. We would like to group all member actions for all controllers (application_controller.rb).

{% highlight ruby -%}
ActiveScaffold.set_defaults do |conf| 
  conf.show.action_group = 'member.actions.crud' 
  conf.delete.action_group = 'member.actions.crud' 
  conf.update.action_group = 'member.actions.crud' 
  conf.nested.action_group = 'member.actions.nested'
end
{%- endhighlight %}

To add some custom actions to a new collection group you can do something like this:

{% highlight ruby -%}
class TeamsController < ApplicationController
  active_scaffold :team do |conf|
    ....
    conf.action_links.collection.custom do |group| 
      group.name = I18n.t( '<...>.custom' ) # set the group's name    
      group.add 'dummy1', :confirm => 'are_you_sure', :type => :collection, :method => :put, :position => false
      group.level_2 do |group| 
        group.add 'dummy2', :confirm => 'are_you_sure', :type => :collection, :method => :put, :position => false 
      end 
      group.add 'dummy3', :confirm => 'are_you_sure', :type => :collection, :method => :put, :position => false 
    end 
    ....
  end
end
{%- endhighlight %}

Adding member actions to a new group is the same as collection actions:

{% highlight ruby -%}
class TeamsController < ApplicationController
  active_scaffold :team do |conf|
    ....
    conf.action_links.member.custom do |group| 
      group.add 'dummy1', :confirm => 'are_you_sure', :type => :member, :method => :put, :position => false
      group.level_2 do |group| 
        group.add 'dummy2', :confirm => 'are_you_sure', :type => :member, :method => :put, :position => false 
      end 
      group.add 'dummy3', :confirm => 'are_you_sure', :type => :member, :method => :put, :position => false 
    end 
    ....
  end
end
{%- endhighlight %}

As of September, 25th 2012, the master branch contains a commit by Sergio allowing to define different groups for nested links as well. Here an example of how to use it:

{% highlight ruby -%}
    conf.nested.add_link(:nested_as, :action_group => 'member.ownlinksA')
    conf.nested.add_link(:nested_bs, :action_group => 'member.ownlinksA')
    conf.nested.add_scoped_link(:nested_cs, :action_group => 'member.ownlinksB')
{%- endhighlight %}
