---
title: "Security: declarative authorization"
category: "Integrations"
---

Here are some tips on using [declarative_authorization](https://github.com/stffn/declarative_authorization) with ActiveScaffold's security model. These tips assume you already know how to use declarative_authorization.

## Settings

### security.default_permission <small><em>global</em></small>

From the [Security](/doc/security/) page:

> A boolean value for what a security check should return in the absence of a relevant method. The default is `true`, which lets ActiveScaffold work out of the box. If you need to be security conscious in your application, you should consider setting this to `false` so that nothing works until you permit it.

Unfortunately, this doesn't seem to work. In order to get things working I had to comment the line out so that it would default to `true`. I also added a few other methods to the ApplicationController.

{% highlight ruby -%}
class ApplicationController < ActionController::Base

  # Set up the current user for declarative_authorization
  before_filter { |c| Authorization.current_user = c.current_user }

  # Handle security errors
  rescue_from ActiveScaffold::ActionNotAllowed, :with => :permission_denied

  ActiveScaffold.set_defaults do |config|
    # config.security.default_permission = false
  end

  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    redirect_to root_url
  end
end
{%- endhighlight %}

## Controllers

Do not use `filter_resource_access` in your controllers. Instead, implement the `#{action_name}_authorized?` methods like this:

{% highlight ruby -%}
class PostsController < ApplicationController
  # filter_resource_access

  active_scaffold :post do |conf|
  end

  def create_authorized?
    permitted_to? :create, :posts
  end

  def show_authorized?(record = nil)
    permitted_to? :read, :posts
  end

  def list_authorized?
    permitted_to? :read, :posts
  end

  def update_authorized?(record = nil)
    permitted_to? :update, :posts
  end

  def delete_authorized?(record = nil)
    permitted_to? :delete, :posts
  end

end
{%- endhighlight %}

## Models

Do not use `using_access_control` at the top of your models. Instead implement the `authorized_for_#{crud_type}?` methods like this:

{% highlight ruby -%}
class Post < ActiveRecord::Base
  # using_access_control

  belongs_to :author
  has_many :comments

  def self.authorized_for :create
    self.permitted_to? :create
  end

  def authorized_for_read?
    permitted_to? :read
  end

  def authorized_for_update?
    permitted_to? :update
  end

  def authorized_for_delete?
    permitted_to? :delete
  end

end
{%- endhighlight %}

And that is pretty much it. If you don't implement these methods on a particular model/controller, then you won't have any security on them.