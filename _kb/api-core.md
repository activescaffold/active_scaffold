---
title: "API: Core"
category: "API Reference"
---

## actions <small><em>global local</em></small>

The components of ActiveScaffold (e.g. Create, Update, Delete, Show) are called actions. This setting lets you define which ones are active. Only actions present in this list will be configurable. Only actions present in this list will be mixed into your controllers.

Examples:
{% highlight ruby -%}
config.actions = [:create, :update, :show]
config.actions.exclude :create
config.actions.add :delete
config.actions.swap :search, :live_search
{%- endhighlight %}

## action_links <small><em>global local</em></small>

If you want to tie ActiveScaffold to a custom action, or to some other page or controller or site or whatever, you can create your own action link. This setting is just for your _custom_ action link: the action links used by various action components are editable within the configuration for that action component (e.g. `config.create.link`). See [API: Action Link](/doc/api-action-link/) for details on the per-link options.

Examples:

{% highlight ruby -%}
# Add an action link (with options)
config.action_links.add 'get_pdf', :label => 'Download PDF'

# You can look up and modify action links by searching by the :action attribute
config.action_links['get_pdf'].label = 'Save PDF'

# Quick-add (doesn't accept options)
config.action_links << 'print_pdf'

# NOTE: if you want to edit a "native" link, you can find it on the proper config object
config.show.link.label = 'Display Record'
{%- endhighlight %}

## after_config_callbacks <small><em>global local v3.6+</em></small>

Define methods or procs to be called after active_scaffold config block runs. It can be used to run code on every controller, defining the proc in the initializer, a class method in `ApplicationController` or a method in `ActiveScaffold::Config::Core` (useful for ActiveScaffold gems or bridges, as `BitfieldsBridge` does):

{% highlight ruby -%}
ActiveScaffold.defaults do |conf|
  conf.after_config_callbacks << proc do
    if active_scaffold_config.actions.include?(:field_search) && active_scaffold_config.actions.include?(:search)
      active_scaffold_config.field_search.link.parameters = {:kind => :field_search}
    end
  end
end
{%- endhighlight %}

Or using a class method in ApplicationController with common configuration:

{% highlight ruby -%}
class ApplicationController < ActionController::Base
  protected

  def self.two_search_config
    active_scaffold_config.field_search.link.parameters = {:kind => :field_search}
    active_scaffold_config.list.always_show_search = true
  end
end

ActiveScaffold.defaults do |conf|
  conf.after_config_callbacks << :two_search_config
end
{%- endhighlight %}

## cache_action_link_urls <small><em>global local v3.3+</em></small>

ActiveScaffold caches action link urls since v3.3. If you use nested resources routes to get pretty routes without query string, you will need to disable caching, or you will get longer urls because parameters will be added to query string anyway.

Examples:
{% highlight ruby -%}
# config/routes.rb
resources :customers do
  as_nested_resources :invoices
end

# app/controllers/application_controller.rb
ActiveScaffold.set_defaults do |config|
  config.cache_action_link_urls = false
end

# or only in invoices controller
# app/controllers/invoices_controller.rb
active_scaffold do |conf|
  conf.cache_action_link_urls = false
end
{%- endhighlight %}

## cache_association_options <small><em>global local v3.3.1+</em></small>

ActiveScaffold caches cache_association_options since v3.3.1. It is useful for has_many associations rendered as subform. Association name, class owner of the association, associated class (for polymorphic associations), and conditions returned by options_for_association_conditions must be equal to reuse cached result. If association_options_find gets a block (due to some overrided methods), or default class is overrided (e.g. overriding method to use a scope), cache is skipped. Anyway, if cache is causing problems to you, it can be disabled with this option.

Example:
{% highlight ruby -%}
# app/controllers/application_controller.rb
ActiveScaffold.set_defaults do |config|
  config.cache_association_options = false
end

# or only in invoices controller
# app/controllers/invoices_controller.rb
active_scaffold do |conf|
  conf.cache_association_options = false
end
{%- endhighlight %}

## columns <small><em>local</em></small>

The columns setting is a collection of metadata about attributes of your model. Columns in here may be simple attributes, virtual fields (fields with just an accessor on the model), or associations. See [API: Column](/doc/api-column/) for details on per-column configuration.

If you want to remove a particular column from use in a particular action, then use the appropriate config.#{action}.columns collection (e.g. config.list.columns).

Examples:

{% highlight ruby -%}
# Add a column (virtual, probably)
config.columns.add :first_and_last_name
config.columns << :name_spelled_backwards

# Edit a column (options described below)
config.columns[:first_and_last_name].label = 'Full Name'

# Remove a column from Create, Update, List, etc. (version 1.1+)
config.columns.exclude :sekret_field
{%- endhighlight %}

Note that if excluding and re-adding columns, the order/weight of columns may seem disregarded if class caching is enabled (if config.cache_classes=true in development.rb, test.rb, and/or production.rb). If this is the case, you should first reset columns to their initial state via:  

{% highlight ruby -%}
active_scaffold_config.list.columns = active_scaffold_config.columns._inheritable
{%- endhighlight %}

This solution of resetting columns prior to additions and exclusions is preferred since it supports class caching being enabled or disabled. For more information, please read <a href="https://code.google.com/p/activescaffold/issues/detail?id=732">issue 732</a> and <a href="https://stufftohelpyouout.blogspot.com/2010/03/activescaffold-and-column-order.html">this post</a>.

## conditional_get_support <small><em>global local v3.4+</em></small>

Enable setting `Etag` and `LastModified` on responses and using fresh_when/stale? to respond with 304 and avoid rendering views. Etag is calculated only for get requests and based on `record or `records. To change records used to calculate etag, override `objects_for_etag` in your controller.

### config.list.columns, config.create.columns, config.update.columns inherit from config.columns

By default, `config.columns` contains all of the columns for your model, including primary key, foreign key identifiers, created/updated_on/at, etc.  These other fields

`config.list.columns`, `config.create.columns`, and `config.update.columns` inherit their columns from config.columns.  However, some columns are excluded by default: foreign key identifiers such as ``user_id``, the ``id`` column, and the ``created/updated_at/on``  fields.

After v3.4.33 config.update.columns are inherited from config.create.columns, if not defined.

### Real, Association, and Virtual Columns

The minimum requirement for an ActiveScaffold column is an accessor on the model. If the accessor is named the same as a database attribute, then it's a "real" column. If the accessor is named the same as an association, then it's an "association" column (these accessors are a special type of virtual column created and managed by ActiveRecord, e.g. @`user.user_group`). Otherwise it's a "virtual" column.

In general, ActiveScaffold's default column set will include one column for every database attribute and one column for every association. If you want to use virtual columns (which can be very handy), you'll need to add them in yourself.

Examples:

{% highlight ruby -%}
class User < ActiveRecord::Base
  # defining an association will also create an association column with the same name
  has_and_belongs_to_many :roles

  # create an accessor that can be used as a virtual column
  def first_and_last_name
    "#{self.first_name} #{self.last_name}"
  end
end

class UserController < ApplicationController
  active_scaffold :users do |config|
    # In the List view, we'll combine two fields into one by hiding two "real" fields and adding one "virtual" field.
    config.list.columns.exclude :first_name, :last_name
    config.list.columns << :first_and_last_name

    # If you want to customize the metadata on the virtual field, you need to add it to the main columns object.
    config.columns << :first_and_last_name
    config.columns[:first_and_last_name].label = 'Full Name'
  end
end
{%- endhighlight %}

## custom_modules <small><em>global local v4.2+</em></small>

Custom modules are included in the controllers using ActiveScaffold, after all other ActiveScaffold modules are included (`Finder`, `AttributeParams`, action modules, ...). It can be used to override ActiveScaffold methods in every controller, using the global config in `defaults`, as concerns do but without requiring to include the module in every controller manually. It works to override methods added to controllers with ActiveScaffold modules, after the active_scaffold block runs, because overriding them in ApplicationController doesn't work.

{% highlight ruby -%}
module CustomActiveScaffoldMethods
  def export_authorized?(*)
    super && current_user.admin?
  end
end

ActiveScaffold.defaults do |config|
  config.custom_modules << CustomActiveScaffoldMethods
end
{%- endhighlight %}

It can be used per controller too, which is almost the same as calling `include` after `active_scaffold` block, but it runs before ActiveScaffold config is frozen, so it allows to make changes calling `active_scaffold_config` in `included`:

{% highlight ruby -%}
module TwoSearchConfig
  extend ActiveSupport::Concern

  included do
    active_scaffold_config.field_search.link.parameters = {:kind => :field_search}
    active_scaffold_config.list.always_show_search = true
  end
end

active_scaffold do |conf|
  ...
  conf.custom_modules << TwoSearchConfig
end
{%- endhighlight %}
    

## formats 

Active scaffold supports html, js, json and xml formats by default.  If you need to add another mime type for your controller you can do it here.  The format is then added to the default formats.

Examples:

{% highlight ruby -%}
# Add a column (virtual, probably)
config.formats << :pdf
or
config.formats = [:pdf]
{%- endhighlight %}

## frontend <small><em>global local</em></small>

ActiveScaffold is skinnable by creating and using different frontends. These frontends can package up completely different javascript, stylesheets, images, language files, and partials. They are a powerful way of potentially changing the entire UI for ActiveScaffold to blend with your design. Any partial called for by the ActiveScaffold code that is not provided by a frontend will fallback to using the partial from the default frontend.

When more frontends are shipped with ActiveScaffold, or when you have written your own, you can decide which frontend to use either globally or on a per-controller basis.

Examples:

{% highlight ruby -%}
config.frontend = :shiny_new_frontend
{%- endhighlight %}

**Note:** Not working in current version. Only up to 2.3.8. 

## highlight_messages <small><em>global local v3.2.12</em></small>

Set this option to highlight some words of the flash messages. It will use highlight rails helper, so you can set phrases as keys (a string or array of strings to highlight) and format strings as values. Look at highlight rails API for more info about this method.

{% highlight ruby -%}
config.highlight_messages = {'created' => '<em>\\1</em>'}
{%- endhighlight %}

## ignore_columns <small><em>global</em></small>

If your database schema has special fields that should just be ignored by ActiveScaffold, you can define a global blacklist here. <strong>This is meant to be used on the ApplicationController</strong>. If you want to exclude columns in some specific scaffold, use the `config.#{action}.columns.exclude` method.

Examples:

{% highlight ruby -%}
config.ignore_columns = [:created_at, :updated_at, :lock_version]
config.ignore_columns.add :is_deleted
{%- endhighlight %}

## label <small><em>local</em></small>

This is a string giving a base name for the entire scaffold. This base name will be extended appropriately by actions, unless those actions have explicitely defined their own labels. For example, if might set `config.label = 'Customers'`, and then the Create action would have a label like "Create Customer". This label makes the most sense as a plural noun describing the records in the collection. 

Examples:

{% highlight ruby -%}
config.label = 'Customers'
{%- endhighlight %}

## sti_children <small><em>local v2.3</em></small>

Set it in a controller for a superclass model of a hierarchy. Set an array with names of subclasses. The inheritance column will use form_ui select, and the subclasses will be used as options for the select. If you set another form_ui for the column it won't be overridden.

{% highlight ruby -%}
config.sti_children = [:subclass1, :subclass2]
{%- endhighlight %}

## sti_create_links <small><em>global local v2.3</em></small>

It's only used when sti_children is used. Enabling it, create link will be changed with multiple create links for each subclass from sti_children. Also type column will be hidden in create and update forms.

## store_user_settings <small><em>global local v3.3.1</em></small>

Enable saving user settings in session (per_page, limit, page, sort, search params). It's enabled by default becuase it was the previous behaviour.

When it's disabled search params will be send in every sorting and pagination request, and sort params will be send in every pagination request, instead of getting them from session. Also, closing and opening search form won't display previous search params.

## timestamped_messages <small><em>global local v3.2.12</em></small>

Prefix flash messages with current timestamp. You can set true and :short format will be used, or set the format to display, either a string format or a I18n format key.

## theme <small><em>global local</em></small>

For each frontend there may by a set of available themes: different look and feels for the same underlying UI (frontend). Themes are entirely CSS based.

Examples:

{% highlight ruby -%}
config.theme = :default
config.theme = :blue # AjaxScaffold look with a blue header
{%- endhighlight %}

## active_scaffold_controller_for <small><em>override method</em></small>

This _class_ method accepts an ActiveRecord::Base klass and returns an ActionController::base klass (a constant, not a string). We use the method to link controllers together (like for [API: Nested](/doc/api-nested/)), and to find configuration of associated models (like for [API: Subform](/doc/api-subform/)). The default behavior is to try and search for a singular or plural version of #{model}Controller within the namespace of the current controller. If this doesn't work for you, maybe because you have your own convention or because you have one controller that doesn't match up, you can override active_scaffold_controller_for to define your own search pattern.

Example:

{% highlight ruby -%}
class Admin::Scaffold::ScaffoldTableController < Admin::Scaffold::BaseController
  protected

  def self.active_scaffold_controller_for(klass)
    return FooController if klass == Bar
    super
  end
end
{%- endhighlight %}
