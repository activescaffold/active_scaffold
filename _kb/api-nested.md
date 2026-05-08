---
title: "API: Nested"
category: "API Reference"
---

## Overview

The `nested` feature set allows you to easily edit relational data for your models <small>(See example below)</small> all on the same page.

The :nested action MUST be included if you are using nested scaffolds (it is included by default).  If you are limiting the actions available using config.actions=, you must include :nested

{% highlight ruby -%}
config.actions = [:list, :nested]
{%- endhighlight %}

Nested links can be disabled by removing the action as follows:

{% highlight ruby -%}
config.actions.exclude :nested
{%- endhighlight %}

## add_link <small><em>local</em></small>

Lets you add an Action Link configured to open a nested scaffold for the given association. You should specify association name as they are found in the config.columns collection, not model names or table names.

Example: 
Create an action link to open all "contacts" for a row

{% highlight ruby -%}
# app/models/company.rb
class Company < ActiveRecord::Base
   has_many :contacts
end

# app/models/contact.rb
class Contact < ActiveRecord::Base
  belongs_to :company
end

# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  active_scaffold :contact do | config |
  end
end

# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  active_scaffold :company do |config|
    config.nested.add_link(:contacts)
  end
end
{%- endhighlight %}

[/images/nested_example_1.jpg](/doc/images-nested_example_1-jpg/)
<small>Figure 1.0: A nested scaffold for the above example</small>

You can also set options for link as last parameter. Some options have a default value, such as type, controller, security_method, position, refresh_on_close and label, but they can be overrided. Nested parameters (parent_scaffold, association, and parent model's id) are added to the provided parameters.

{% highlight ruby -%}
config.nested.add_link(:contacts, :label => "Company's contacts", :page => true)
{%- endhighlight %}

Action defaults to `index` but it can be changed to something else, for example using `new`, `show` or `edit` on singular associations, or nil to set the action automatically as it happens in singular association columns in the list. It can be set to `new` for plural associations too, but it's better to use `add_new_link` as it adds `parent_controller` param so the parent row is refreshed on the create response. 

## add_new_link <small><em>local</em></small>

Lets you add an Action Link configured to open a nested create form for the given association. You should specify association name as they are found in the config.columns collection, not model names or table names. As in `add_link`, you can also set options for link as last parameter, for example, it's good to set the security_method, as checking create permission on the associated model may be needed. Nested parameters (parent_scaffold, association, and parent model's id) and `parent_controller` are added to the provided parameters, so the parent row is refreshed on the create response.


{% highlight ruby -%}
# app/models/company.rb
class Company < ActiveRecord::Base
   has_many :contacts
end

# app/models/contact.rb
class Contact < ActiveRecord::Base
  belongs_to :company
end

# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  active_scaffold :contact do | config |
  end
end

# app/controllers/companies_controller.rb
class CompaniesController < ApplicationController
  active_scaffold :company do |config|
    config.nested.add_new_link(:contacts, security_method: :add_contact_authorized?)
  end

  protected

  def add_contact_authorized?(record)
    Contact.authorized_for?(crud_type: :create)
  end
end
{%- endhighlight %}

## add_scoped_link <small><em>local</em></small>

Lets you add an Action Link configured to open a nested scaffold for the given scope, for example to open a nested scaffold with children scope from Ancestry gem.

Example: 
Create an action link to open all "contacts" for a row

{% highlight ruby -%}
# app/models/menu.rb
class Menu < ActiveRecord::Base
   has_ancestry
end

# app/controller/menus_controller.rb
class MenusController < ApplicationController
  active_scaffold :menu do |conf|
    conf.nested.add_scoped_link(:children)  #nested link to children
  end

  protected 

  # If nested let active_scaffold manage everything
  # if not just show all root nodes
  def beginning_of_chain 
    nested? ? super : active_scaffold_config.model.roots 
  end 

  # Assign parent node to just created node
  def after_create_save(record) 
    if (nested? && nested.scope) 
      parent = nested_parent_record(:read) 
      record.send("#{nested.scope}").send(:<<, parent) unless parent.nil? 
    end
  end 
end
{%- endhighlight %}

## formats <small><em>local</em></small>

Active scaffold supports html, js, json, yaml, and xml formats by default.  If you need to add another mime type for nested associations you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
config.nested.formats << :pdf
# or
config.nested.formats = [:pdf]
{%- endhighlight %}

## ignore_order_from_association <small><em>v3.3+ global local</em></small>

ActiveScaffold will sort the nested list using :order option from association if is set, ignoring list.sorting. Enabling this option will ignore :order option from association definition and will use list.sorting for nested scaffolds too, like it does for non-nested lists.

## shallow_delete <small><em>v1.1 global local</em></small>

Default value is false. If set to true, the delete action in a habtm association is replaced with delete existing.

Example: 

{% highlight ruby -%}
config.nested.shallow_delete = true
{%- endhighlight %}

## Other methods of adding nested scaffolds

Attach a link to a column:

{% highlight ruby -%}
columns[:contacts].set_link('nested', :parameters => {:associations => :contacts})
{%- endhighlight %}

Attach a link to a column  that will open up many nested scaffolds at time

{% highlight ruby -%}
columns[:contacts].set_link('nested', :parameters => {:associations => "contacts projects"})
{%- endhighlight %}

## Configuring the Nested Scaffold

ActiveScaffold tries to find the configuration for the nested scaffold by searching for a controller named in a conventional `#{model_name}Controller` fashion. So for example, if a Company has_many :contacts, then when CompaniesController tries to nest ContactsController it will try to take the configuration from a  ContactsController. Failing that, it will use a default configuration.

If the default behavior for finding configuration from a conventional controller doesn't work for you, you may override the `active_scaffold_controller_for` method and define your own search rules. See [API: Core](/doc/api-core/) for more information.

If you need different configuration in a scaffold when is nested, you will have to use [per-request configuration](/doc/per-request-configuration/).

## Reverse Associations

Nested scaffolds depend on something we call the "reverse association". Associations are technically uni-directional, but in practice they are bi-directional. That is, when you set up an association like `Contact :belongs_to :company`, you've only set up one direction. In order to make it bi-directional you must also say that `Company :has_many :contacts`. In this setup, the reverse association for Company#contacts is :company, and the reverse association for Contact#company is :contacts.

ActiveScaffold does its best to find the reverse association. If for some reason this best effort attempt fails, you may specify the reverse association by editing the column object as in the example below. Note that the example below is not strictly necessary - ActiveScaffold should find reverse associations even if the name is slightly unconventional.

{% highlight ruby -%}
active_scaffold :companies do |config|
  config.columns[:contacts].association.reverse = :company
end
{%- endhighlight %}

> If you are modifying the @config.columns collection, make sure the association column is present on both sides of the association. Any column used by ActiveScaffold, in this case the association columns, needs to exist in this collection.
