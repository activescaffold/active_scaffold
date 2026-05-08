---
title: "API: Action Link"
category: "API Reference"
---

Action Links are used to tie pieces of ActiveScaffold together, and can be used to integrate your own functionality. They can be attached and configured in a variety of places. Native actions like Create, Update, and Delete have configurable links within their own config sections (e.g. `config.create.link`), and column objects may themselves have an action link (e.g. `config.columns[:username].link`). The main `config.action_links` collection is meant for your custom links.

## action

The :action value of the URL

## confirm

The confirmation message for the link, if any.

If the message is a symbol, it will be translated under `active_scaffold` scope, with `as_` method. The translation may use `%{label}` variable for interpolation.

## controller <small><em>v1.1</em></small>

Lets you specify a different controller for the action link. In version 1.0 you had to sneak this in through the `:parameters` option.

## crud_type

Specifies that the (eventual) CRUD action initiated by this link will be one of the core CRUD types. This is used to check authorization and disable the link.

Values: :create, :read, :update, :destroy

## dynamic_parameters

A block to return miscellaneous parameters for the URL. In member action links the block must accept one argument and it will get the record. It must return a hash which will be used as url parameters.

## html_options

Html attributes to render this action link

## ignore_method

Specifies a method on the controller that determines whether to show this link or not. Note that this does NOT prevent someone from URL hacking. Method needs to have record parameter (e.g. :logged_in?( record = nil ) ). The method must return false (or nil) to display the link, in other case link will be skipped.

Values: a symbol naming the method (e.g. `:logged_in?`)

{% highlight ruby -%}
# Example
config.create.link.ignore_method = :hide_create?
{%- endhighlight %}

## image

Set a hash to display an image instead of text. The hash must have :name key with the file name and :size key with the geometry string:

{% highlight ruby -%}
active_scaffold_config.action_links.add :mail, :image => {:name => '/assets/icons/mail.png', :size => '16x16'}, :type => :member, :position => false
{%- endhighlight %}

## inline

When true, the link will open with an AJAX call, using the `:position` option.

Values: true, false

## keep_open

Enabling this option, the view won't be closed when other action links open a view.

## label

The visible text for the link.

Label can be set to a proc or lambda to support defining dynamic label.

{% highlight ruby -%}
config.nested.add_link(:accounts, label: Proc.new { |record| "Accounts (%s)" % record.accounts.count })
{%- endhighlight %}

## method

Specifies a method for RESTful links. Default is `:get`.

Values: :get, :post, :put, :delete

## page

When true, the link will open with standard HTML behavior.

Values: true, false

## parameters

Miscellaneous parameters for the URL. In version 1.0, if you want to link to another controller you need to specify a :controller parameter here.

## popup

When true, the link will open in a new window. Currently there is no configuration option to set the size of the new window.

Values: true, false

## position

For inline links, determines where the result goes. When set to false, then ActiveScaffold will not try to automatically place the result (good for RJS responses, or e.g. in cases, where the action involved is not expected to return a view).

Values:
- for `:type => :collection`: :top, :popup, false.
- for `:type => :member`: :replace, :after, :before, :table, :popup, and false.

When using :popup, it will open a popup in the same page, with Dialog widget from jQuery UI, so jQuery UI is needed to use :popup position. Also, it's possible to use a different library, replacing ActiveScaffold.open_popup and ActiveScaffold.close_popup functions.

## prompt

A prompt message for the link, so it will be used to prompt for input before submitting the action. It works only on inline links, and the value will be submitted as `value` parameter. The action link may use GET, POST, PUT or PATCH method to send the request.

If no value is entered, the request will be sent without `value` parameter, unless `prompt_required` is enabled in the action link, which will prevent sending the action if prompt is cancelled or accepted with no value.

If the message is a symbol, it will be translated under `active_scaffold` scope, with `as_` method. The translation may use `%{label}` variable for interpolation.

## prompt_required

Disabled by default, when it's enabled, it will prevent sending the request if prompt is cancelled or accepted with no value.

## refresh_on_close

After closing the view displayed with the action link, row will be refreshed. It's enabled by default on nested action links. It must be used on inline action links with position, it has no effect in page action links or action links without position.

## security_method

Specifies a method on the controller that determines whether to disable this link or not. Note that this does NOT prevent someone from URL hacking. Method needs to have record parameter (e.g. :logged_in?( record = nil ) ). The method must return false (or nil) to disable the link.

Values: a symbol naming the method (e.g. `:logged_in?`)

## type

Determines whether the link appears on each record, or just once for the entire scaffold.

Values: :collection, :member

Before v2.3, values: :table, :record

## weight <em>v3.4+</em>

Add a weight to the action link to override default sorting. Action links are sorted from lowest weight to highest one, and action links with same weight will be displayed in creation order. A default weight can be set for default links:

{% highlight ruby -%}
  ActiveScaffold.set_defaults do |config|
    config.delete.link.weight = 100
  end
{%- endhighlight %}

See [Action Links Order](/doc/action-links-order/) for more details.

## Examples:

{% highlight ruby -%}
config.show.link = false     #This removes the show link from the list view, but still allows the show function to be used.
config.update.link.inline = false     #This sets the update link to open in its own page.
{%- endhighlight %}

## To enable or disable action links on a per record basis:

Create an `authorized_for_#{action}?` (e.g. authorized_for_destroy?) in your model and return false for disabling the action link based on your conditions. You can create two methods for column level security checks for every CRUD action, such as `#{column}_authorized_for?` or `#{column}_authorized_for_#{action}?`.

{% highlight ruby -%}
class MyModel < ActiveRecord::Base
  def authorized_for_delete?
     false
  end
  def authorized_for_update?
     false
  end
end
{%- endhighlight %}

You can override the authorized_for? method in your model and return false for disabling action_links based on your conditions, but then you can't use `#{column}_authorized_for?`, `authorized_for_#{action}?` or `#{column}_authorized_for_#{action}?`. For action_links do something like this:

{% highlight ruby -%}
class MyModel < ActiveRecord::Base
  def authorized_for?(*args)
     not [:destroy, :update].include?(args[0][:action]) 
  end
end
{%- endhighlight %}

## Example: Adding "To PDF" Action Link

To the routes.rb file add the following:

{% highlight ruby -%}
  resources :orders do 
    member do
      get 'to_pdf'
    end
    as_routes 
  end
{%- endhighlight %}
This will add an /orders/:id/to_pdf(.:format) route.

To the controller add the following:

{% highlight ruby -%}
  active_scaffold :order do |conf|
    conf.action_links.add 'to_pdf', :label => 'To PDF', :page => true, :type => :member, :parameters => {:format => 'pdf'}
  end

  def to_pdf
    @order = Order.find(params[:id])
  end
{%- endhighlight %}

Then use something like prawn_rails and create a to_pdf.pdf.prawn view to render your PDF output.

> It's better to use show view with :pdf format (/orders/:id.pdf route in the example). Add :action => :show to action link options
