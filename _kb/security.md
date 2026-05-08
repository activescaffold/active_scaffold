---
title: "Security"
category: "API Reference"
---

If you want to deploy ActiveScaffold in production and expose it to possibly untrusted users, you can take advantage of its security layer to protect your data. The security layer works by paying attention to methods that you can define on your models and controllers. With these methods you may restrict access by taking into account any of the following, as appropriate: the ActiveRecord model, the database record, the current/intended action, and the current user. You may also restrict access at various levels of granularity, forbidding access to an entire action, an entire record, or just a column on the record.

> Disclaimer: It's recommended to test your security setup! If your data is critical and you want complete peace of mind, you must test it yourself. Make sure you have been as specific as possible, and that you have tested to make sure your security methods are being used.

> Note about CanCan: If you install the [CanCan](https://github.com/ryanb/cancan) authorization package, ActiveScaffold will use the CanCan bridge and <em>not</em> the native ActiveScaffold security authorization methods described below. See [CanCan](/doc/cancan/) in this wiki.

## Settings

### security.current_user_method <small><em>global</em></small>

Names a method on the controller that should return the current_user object, when available. The default is `:current_user`, which fits nicely with devise, acts_as_authenticated, etc.

{% highlight ruby -%}
class ApplicationController < ActionController::Base

  ActiveScaffold.defaults do |config|
    config.security.current_user_method = :current_login
  end

  protected

  def current_login
    @session[:user_id] ? User.find(@session[:user_id]) : nil
  end
end
{%- endhighlight %}

### security.default_permission <small><em>global</em></small>

A boolean value for what a security check should return in the absence of a relevant method. The default is `true`, which lets ActiveScaffold work out of the box. If you need to be security conscious in your application, you should consider setting this to `false` so that nothing works until you permit it.

{% highlight ruby -%}
class ApplicationController < ActionController::Base

  ActiveScaffold.set_defaults do |config|
    config.security.default_permission = false
  end
end
{%- endhighlight %}

## How security is enforced

ActiveScaffold checks the permissions in 3 situations:

- When rendering the action links.
- When actions are requested.
- When rendering columns, in list and forms.

### Permission checks rendering action links

When an action link is rendered, ActiveScaffold will check permissions in different ways, with controller or model method, depending on security_method setting, or existence of a controller method with a standard name.

If the action link has a value in the attribute security_method, it will be the name of a controller method. This method will be used to check permission. If the action link has no security method, but the controller has a method named "<action>_authorized?", it will be used in the same way. The record is passed to the security method for member action links, so the method must accept one argument. If the action link is authorized it will be rendered as a link, otherwise will be rendered as a disabled link if it's a member action, or not rendered if it's a collection action.

If the action link has no security method, and the controller has no method named "<action>_authorized?", then AS will check permission in the model for member action links, calling record.authorized_for?(crud_type: link.crud_type, action: link.action), crud_type is :read by default if not defined in the action link.

The ActiveScaffold actions have a security_method by default, and the action defines the security method in the controller, these methods check authorized_for? with crud_type, in the model for create action, and in the record instance for other actions when called to render the link.

### Permission checks on action request

ActiveScaffold actions add a before_action method which calls the security method of the action link, for the ActiveScaffold own actions. Custom actions will need to setup this before action if wanted. The before_action will call the security method with no argument, as record is not loaded yet although it's a member action, so the security methods for ActiveScaffold member actions must have one argument optional, as it's called with record when rendering the link, and without record from the before_action method.

The security methods of the ActiveScaffold actions checks authorized_for? with crud_type, in the model when called from before_action method, so class method in the model can be used to allow or reject an action based on current user, but not based on the current record.

Then the ActiveScaffold member actions load the record with `find_if_allowed`, with a crud_type, so they will call `authorized_for?` in the record instance to check permissions again, this time allowing or rejection may depend on the record data.

When adding a custom action, before_action methods should be added if needed, and record should be loaded with `find_if_allowed` to ensure permissions are checked, or using `process_action_link_action` which uses `find_if_allowed` internally (this method is explained in [Adding-custom-actions](/doc/adding-custom-actions/)). When calling `find_if_allowed`, the second argument may be a symbol used as `:crud_type` for `authorized_for?`, or a Hash of options for `authorized_for?` method.

### Permission checks on columns

When ActiveScaffold loops on the action columns, it calls `authorized_for?` with `:crud_type` and `:column` options. The value of `:crud_type` depends on the used action, e.g. on index or show action, it's `:read`, on create action it's `:create`, and it's `:update` for update action. However, if `show_unauthorized_columns` is enabled on create or update, then will use `:read` for `:crud_type`. If the method returns false, then the column is not rendered.

On index action, to render the list, the visible columns are checked by calling `authorized_for?` on the model, as a class method, because it's rendered as a table, and all rows must have the same columns, so it can't use the record data to check if the column is allowed or not. Then, when rendering every record's row, it calls `authorized_for?` on the record, as an instance method, and the cell is left blank if the column is not allowed for the record, so it's possible to have some columns allowed for an user, but disallow them in some records, and user won't see the data for those columns on those records.

On member actions, as show action or the form actions, create or update, `authorized_for?` is called on the record, as an instance method. However, when the form has subforms, or association columns using `:horizontal` show UI in the show action, it calls `authorized_for?` in the model, as a class method, to render the table's header and the cells, using `:read` for `:crud_type` even in the forms. Also, it calls `authorized_for?` in the record as an instance method too, with the right `:crud_type` for the record (`:create` if new record in the subform, `:update` if the record is persisted), and will display the value instead of the field if the column is not allowed for the `:crud_type`. In the subform, for persisted records, it will check `authorized_for?` on the record with just `crud_type: :update`, and no field will be render if it isn't authorized for update.

This table summarizes how `authorized_for?` is used in each action:

|_.Action  |_.Show_unauthorized_column    |_.Part|_.Class Method          |_.CRUD type for class|_.Instance Method     |_.CRUD type for instance|
|Index |N/A |N/A |Render or skip the column |:read |Render the data or leave it blank |:read |
|Show |N/A |Main |Not used |N/A |Render or skip the column |:read |
|Show |N/A |Horizontal show_ui |Render or skip the column (header) |:read |Render the data or leave it blank (row) |:read |
|Show |N/A |Vertical show_ui |Not used |N/A |Render or skip the column |:read |
|Create |False |Main |Not used |N/A |Render or skip the column|:create |
|Create |True |Main |Not used |N/A |Render or skip the column |:read |
|Create |True |Main |Not used |N/A |Render the field or data |:create |
|Update |False |Main |Not used |N/A |Render or skip the column|:update |
|Update |True |Main |Not used |N/A |Render or skip the column |:read |
|Update |True |Main |Not used |N/A |Render the field or data |:update |
|Create, update |N/A |Subform |Render or skip the column (header and row) |:read |Render the field or data (row) |:create for new record
:update for persisted records|


What method is called in the model depends on the defined methods, it's explained later, in [Security#model-methods-restricting-anything-else](/doc/security/#model-methods-restricting-anything-else).

## Controller Method: Restricting an Action

You may restrict an entire action (in the ActiveScaffold plugin sense) by defining a method on your controller in the format `#{action_name}_authorized?`. All of the actions are set up with before_action filters that check these controller methods, before loading any record, so forbidding the action in these methods is supposed to be based on the current user's permission, independently of the record. To forbid an action for a specific record, security methods in the model must be used, see next section.

The default behaviour of each controller method is to query the scaffold's ActiveRecord model (see Model Methods below). The model is usually the best place to put a security method, but only methods defined in the controller have access to both session data and the params-hash.

Example:

{% highlight ruby -%}
class PostController
  active_scaffold :posts

  protected

  # only authenticated users are authorized to create records
  def create_authorized?
    # you can also check e.g. :params[:nested] or active_scaffold_constraints[:parent]
    self.logged_in?
  end

  #index action
  def list_authorized?
    current_user.some_boolean_property
  end

end
{%- endhighlight %}

Since version 3, update_authorized? and delete_authorized? has an optional argument, record. Be sure you override them as an optional argument (`record = nil`). If you want to use that argument, remember that record can be nil, because methods will be called with no record too, e.g. use `(record || self).authorized_for?(...)`.

## Model Methods: Restricting Anything Else

On your model object you may define methods (none of which accept any arguments) in any of four formats, depending on your need for granularity. 

The formats are:

  * #{column_name}_authorized_for_#{crud_type}?
  * #{column_name}_authorized?
  * authorized_for_#{crud_type}?
  * authorized_for_#{action_name}?

Hopefully these methods are for the most part intuitive. Crud_type is one of `:create`, `:read`, `:update`, and `:delete`. Column_name is not necessarily the name of a database field. It's the name of whatever column ActiveScaffold is working with, which means it may be a virtual column or it may be an association column.

You may combine methods, and ActiveScaffold will use them intelligently. That is, `#{column_name}_authorized_for_#{crud_action}?` has priority, so when authorized_for? is called with both crud_type and column, it checks only `#{column_name}_authorized_for_#{crud_type}?`. If `#{column_name}_authorized_for_#{crud_type}?` isn't defined, ActiveScaffold will check both `#{column_name}_authorized?` and `authorized_for_#{crud_type}?`.

For example, if you define `authorized_for_update?` and `username_authorized_for_update?` methods, to check permissions for a inplace edit in username column, authorized_for?(:action => :update, :column => :username) is called and ActiveScaffold checks only `username_authorized_for_update?`. But to check permissions for other column, ActiveScaffold will use `authorized_for_update?` because we haven't defined `#{column}_authorized_for_update?` neither `#{column}_authorized?`.

Most methods are defined on the instance level (e.g. `def authorized_for_update?`), but e.g. `def self.authorized_for_create?` is defined as a class method, because there is no record against which the create-permissions can be checked. Thus, `authorized_for_create?` is never called on a record.

`authorized_for_read?`, `authorized_for_update?`, `authorized_for_delete?` and `authorized_for_#{action_name}?` are called as class and instance methods to display action links:
   * if class method disallows, the action link is not displayed for any record.
   * if class method allows, the action link is displayed for all records, but disabled for records which disallow it.

`authorized_for_read?`, `authorized_for_update?` and `authorized_for_delete?` are called as class and instance methods for security checks in the controller:
   * if class method of the model disallows, a before_action filter avoids executing the action without a database query.
   * after loading the record, its model's instance method is called.

`self.authorized_for_create?` is used for both the create action and action links with create crud type, so it must be used to disallow creating a record, because it will disallow access to new and create actions.

Instance methods can return a string with reason for disallowing action, if string is returning to disallow actions, config.security.not_authorized_reason must be enabled in ActiveScaffold.set_defaults block:

{% highlight ruby -%}
# application_controller or initializer
ActiveScaffold.set_defaults do |config|
    config.security.not_authorized_reason = true
end

# model
def authorized_for_update?
  return 'reason for not authorized' unless authorized
  true
end
{%- endhighlight %}

### Tips for Defining Model Security Methods

ActiveScaffold's permissions system actually makes the current user available to your records via the `:current_user` method. This lets you actually pay attention to who's logged in and what their roles/permissions are. You should still be prepared to handle the current_user.nil? scenario, though. The current_user may not exist for anonymous users, during cron scripts, or if the model is accessed outside of a request/response cycle.

{% highlight ruby -%}
def authorized_for_delete?
  # anonymous users may never destroy these/this records
  return false unless current_user
  # unless it's an existing record and a 'permanent' flag has been thrown
  return (self.permanent == false)
end  
{%- endhighlight %}

## What Does NOT Happen

We have tried to design these security methods in a way that lets us spin them off into a new plugin at some future date. The reason they are not a separate plugin yet is because they function passively. That is, they only function when ActiveScaffold is polite enough to care! So please be aware: you can still mess up your data with these security methods in place if you bypass ActiveScaffold (with script/console, for example).
