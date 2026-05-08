---
title: "Adding custom actions"
category: "Advanced"
---

When you add custom actions to a controller which uses ActiveScaffold, probably you will want to keep look and feel. Also, you have to follow some conventions so your action behaves as default actions, and ActiveScaffold provides some methods to DRY your code. Remember defining routes for your custom actions in config/routes.rb, e.g.:

{% highlight ruby -%}
  resources :users do
    # AS default routes  
    as_routes
    # custom action routes
    put :deactivate, :on => :member
    put :archive, :on => :member
    put :reset_password, :on => :member
  end
{%- endhighlight %}


## Refresh list action

One of the easiest actions you can add, is an action which refreshes the list. It could be an action which changes some filtering, for example.

Action links will be rendered inline by default, but you must remember to set :position to false, because your action won't return html code. You can use `:index` action setting a label and some parameters. You can set some conditions in conditions from collection when some parameters are present, or maybe you can set some columns in the parameters and conditions will be added automatically.

{% highlight ruby -%}
  class InvoicesController < ApplicationController
    active_scaffold do |config|
      config.action_links.add :index, :label => 'Show paid', :parameters => {:paid => true}, :position => false
      # it will fiter records with paid set to true
      [more configuration]
    end
  end
{%- endhighlight %}

Another way is using a custom action and calling list method after doing your processing. List method will load records for last page you visited, obeying your last search if it's enabled.

{% highlight ruby -%}
  class InvoicesController < ApplicationController
    active_scaffold do |config|
      config.action_links.add :custom, :position => false
      # it will fiter records with paid set to true
      [more configuration]
    end

    def custom
      flash[:info] = 'custom method called'
      list
    end
  end
{%- endhighlight %}

## Process and refresh action

It could be an action which acts over some marked records, or a record action. It's like delete action, which doesn't display a form and then do some processing. For a collection action it will refresh the list, for a member action it will refresh row and messages, and calculations if are used.

You must remember to set :position to false too, because your action won't return html code. You should set method to :put, because you will change some records, and :crud_type if you want to do security checks with that.

On the other hand, you should use `process_action_link_action` method in your action. This method has two optional arguments:

1. A name to override default responses (`action_update`). If you set this argument, you will have to define `<name>_respond_to_<format>` method for each format you want to respond.
2. The crud_type to check security when loading the record. By default it will try to guess it.

Don't forget to set sucessful to true if all goes right.

{% highlight ruby -%}
  class InvoicesController < ApplicationController
    active_scaffold do |config|
      config.action_links.add :paid, :type => :member, :crud_type => :update, :method => :put, :position => false
      [more configuration]
    end

    def paid
      process_action_link_action do |record|
        if (self.successful = record.paid!)
          flash[:info] = as_(:invoce_paid)
        else
          flash[:error] = as_(:invoce_cannot_be_paid)
        end
      end
    end
  end
{%- endhighlight %}

If you want to process each record in last visited page you can use `each_record_in_page` iterator. If you want to process all records, obeying search and custom conditions (conditions from params, conditions_from_collection, constraints and so on) you can use `each_record_in_scope` iterator. We will use a collection action in these cases.

{% highlight ruby -%}
  class InvoicesController < ApplicationController
    active_scaffold do |config|
      config.action_links.add :paid, :type => :collection, :method => :put, :position => false
      [more configuration]
    end

    def paid
      process_action_link_action do
        self.successful = true
        each_record_in_page { |record| record.paid! }
      end
    end
  end
{%- endhighlight %}

## Form actions

These are actions which displays a form and later process the form, like create or update. You must add two actions: one to display the form and another to process the form (like new and create actions). For displaying form action you can use the `_base_form` partial, and for processing form action you can use process_action_link_action again:

{% highlight ruby -%}
  class InvoicesController < ApplicationController
    active_scaffold do |config|
      config.action_links.add :email, :type => :member, :position => :after
      [more configuration]
    end

    def email
      @record = find_if_allowed(params[:id], :read)
      @column = active_scaffold_config.columns[:email] 
      respond_to_action(:email)
    end

    def send_email
      process_action_link_action do |record|
        self.successful = CustomerMailer.invoice(record).deliver
      end
    end
    protected
    def email_respond_to_js
      render :partial => 'email'
    end
  end
{%- endhighlight %}
{% highlight erb -%}
  # email.html.erb
  <div class="active-scaffold">
    <div class="email-view <%= "#{id_from_controller params[:controller]}-view" %> view">
      <%= render :partial => 'email' -%>
    </div>
  </div>

  # _email.html.erb
  <%= render :partial => "base_form", :locals => {:form_action => :send_email,
                                                :body_partial => 'email_form',
                                                :headline => ""} %>
{%- endhighlight %}

`form_action` is the action to send the form and is used to generate the id attributes, `headline` is the title to display, and `body_partial` is the partial with your form content. It will pass :form_action and :columns to `body_partial`, and by default it will use `form` partial if you don't set, although it only works for actions which have active_scaffold configuration.

`base_form` partial accepts some more options, but they are optional:
* `xhr` defaults to `request.xhr?` in order to use a form or remote form.
* `submit_text` defaults to `form_action`.
* `cancel_link` is true by default, you can remove cancel link setting it to false.
* `method` defaults to :post, you can set it to CRUD method if you want.
* `multipart` defaults to nil.
* `columns` defaults to nil.
* `url_options` defaults to `url_for(:action => form_action)`.

The `_email_form` partial can be build of html form elements or you can reuse your controller AS config:

{% highlight erb -%}
  # _email_form.html.erb
<ol class="form">
  <li class="form-element">
    <%= form_attribute(@column, @record, scope) %>
    <%# for ActiveScaffold 3.2.x %>
    <%#= render :partial => 'form_attribute', :locals => { :column => @column, :scope => scope} %>
  </li>
</ol>
{%- endhighlight %}
