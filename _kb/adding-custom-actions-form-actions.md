---
title: Adding custom actions Form actions
date: "2025-02-17 15:00:28.000000000 +01:00"
permalink: "/wiki-2/adding-custom-actions-form-actions/"
---

These are actions which displays a form and later process the form, like create or update. You must add two actions: one to display the form and another to process the form (like new and create actions). For displaying form action you can use the `_base_form` partial, and for processing form action you can use process\_action\_link\_action again:

```
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

# email.html.erb
   view">
    <%= render :partial => 'email' -%>
# _email.html.erb
<%= render :partial => "base_form", :locals => {:form_action => :send_email,
                                              :body_partial => 'email_form',
                                              :headline => ""} %>
```
`form_action` is the action to send the form and is used to generate the id attributes, `headline` is the title to display, and `body_partial` is the partial with your form content. It will pass :form\_action and :columns to `body_partial`, and by default it will use `form` partial if you don't set, although it only works for actions which have active\_scaffold configuration.

`base_form` partial accepts some more options, but they are optional:

-   `xhr` defaults to `request.xhr?` in order to use a form or remote form.
-   `submit_text` defaults to `form_action`.
-   `cancel_link` is true by default, you can remove cancel link setting it to false.
-   `method` defaults to :post, you can set it to CRUD method if you want.
-   `multipart` defaults to nil.
-   `columns` defaults to nil.
-   `url_options` defaults to `url_for(:action => form_action)`.

The `_email_form` partial can be build of html form elements or you can reuse your controller AS config:

      # _email_form.html.erb

      
        <%= form_attribute(@column, @record, scope) %>
        <%# for ActiveScaffold 3.2.x %>
        <%#= render :partial => 'form_attribute', :locals => { :column => @column, :scope => scope} %>
