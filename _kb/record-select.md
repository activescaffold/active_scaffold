---
title: "Record Select"
category: "Integrations"
---

In general using Record Select allows users to easily "search" for records to create associations.   RecordSelect works well when the number of records to chose from is 50 or more, and a typical select (drop down) UI element becomes difficult to use.

An example:  Let's say you wanted to create work-assignments. Work assignments belong to a user, and a task.  In a system with ~1000 users and ~500 taks, using drop downs to find the user and the task is slow.  Would rather be able to search for the user and task by name, and have the system "find" matches.

To setup record select is very easy.

Step 1.  Add the record select gem to your Gemfile
{% highlight ruby -%}
git 'https://github.com/scambra/recordselect/', branch: 'master' do
  gem 'recordselect'
end
{%- endhighlight %}
Step 2.  Add the record_select configuration to the controller providing the link (associated record)
{% highlight ruby -%}
class UsersController < ApplicationController

  record_select :search_on => [:name, :samAccountName],
                :order_by => 'last_name ASC, first_name ASC',
                label: proc { |r| "#{r.name} | #{r.samAccountName}" }
{%- endhighlight %}
Step 3.  Specify that the column in the controller using the link

{% highlight ruby -%}
class WorkAssignmentsController < ApplicationController

  before_action :check_resource_permissions

  active_scaffold :"work_assignment" do |conf|
    conf.columns[:user].form_ui = :record_select
  end
{%- endhighlight %}
Step 4. Add record_select_routes to routes.rb for the resource

{% highlight ruby -%}
  resources :organizations, concerns: :active_scaffold do
    record_select_routes
  end
{%- endhighlight %}


Adding parameters to record select being used as a subform for another model is also possible.

To add static params to a record select columns, add the following to the relevant controller:

{% highlight ruby -%}
class ParentsController < ApplicationController

  conf.columns[:user].form_ui = :record_select, params: {admin_param: true}

{%- endhighlight %}

And add the param to `permit_rs_browse_params` in the helper, so the param is passed to the search requests issued while typing:

{% highlight ruby -%}
module ParentsHelper
  def permit_rs_browse_params
    (super || []).concat [:endDate]
  end
end
{%- endhighlight %}

If the param needs to be handled dynamically, the following column override can be added to the helper, which replaces usage of form_ui, and calls the helper method for `:record_select` form_ui:

{% highlight ruby -%}
module ParentsHelper
  def parent_user_form_column(record, options)
    column = active_scaffold_config.columns[:user]
    is_admin = current_user.admin? #example dynamic condition
    ui_options = {params: {admin_param: is_admin}}
    active_scaffold_input_record_select(column, options, ui_options: ui_options)
  end
end
{%- endhighlight %}

Afterwards, the query can be changed in the controller:
{% highlight ruby -%}
class UsersController < ApplicationController

  protected
  def record_select_model
   if params[:admin_param] == true 
      query = super.where(condition: true)
    else
      query = super
    end
    query
  end
{%- endhighlight %}


## record_select configuration options
The options you can pass are:

| Syntax | Description |
| --- | ----------- |
|model: | the name of the model you want to expose. defaults based on the name of the controller|
|per_page: | how many records to show per page when browsing|
|notify:  | a method name to invoke when a record has been selected, if you want server-side notification.|
|order_by:  | a SQL string to order the search results|
|search_on:  | a field name, or an array of field names. these fields will each be matched against each search term.|
|full_text_search:  | a boolean for whether to use a %?% search pattern or not. default is false.|
|label:  | a proc that accepts a record and returns a descriptive string. the default one calls :to_label on the record.|
|include:  |as for ActiveRecord::Base#find. can help with search conditions or just help optimize rendering the results.|
