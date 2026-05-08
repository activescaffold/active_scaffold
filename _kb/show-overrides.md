---
title: "Show Overrides"
category: "Customization"
---

In show views columns are rendered with the same format as in list views. If you want to customize the presentation of a column in the show view, you can define a specially named method in your helper file. The format is `#{class_name}_#{column_name}_show_column` or `#{column_name}_show_column`. So, for example, to customize the `:username` column displayed on your show view of `UsersController`, you would add a `user_username_show_column` method to your `UsersHelper` file (the one in app/helpers). If you want to override username columns in all models, add a `username_show_column` method to your `ApplicationHelper` file.

> In v2.3 and previous versions format was only `#{column_name}_show_column`, so method was named `username_show_column`.

This override method accepts two arguments: the entire record object and the column. It is your responsibility to retrieve the interesting value from the record.

> Before version 3.3, the override method accepted only a single method, the record object, so would be defined for example as "def phone_column(record)". Since version 3.3 this would be written "def phone_column(record, column)".

This override method is used by Show.

Example:

{% highlight ruby -%}
 class User < ActiveRecord::Base
   has_many :roles
 end

 module UsersHelper
   # joins the first three roles with a hyphen instead of the normal comma.
   # ok, so this one isn't very original.
   def user_roles_show_column(record, column)
     record.roles.first(3).collect{|role| h(role)}.join(' - ')
   end

   # creates a popup link to the associated division (belongs_to association)
   def user_division_show_column(record, column)
     link_to(h(record.division.name), :action => :show, :controller => 'divisions', :id => record.division.id)
   end
 end
{%- endhighlight %}

If the association is defined in a STI model, prefixing with the base class is supported too, so subclasses can use a helper override prefixed with own class name, which is specific for the subclass, or share a helper override with the base class name prefix. For example:

{% highlight ruby -%}
class Admin < User
end

class Member < User
end
{%- endhighlight %}

Admin will look for `admin_roles_show_column` and `user_roles_show_column`, and Member will look for `member_roles_show_column` and `user_roles_show_column`, so `user_roles_show_column` can be defined to use the same field in both models. This is more useful when `clear_helpers` is not called in `ApplicationController`, or when the method is defined in `ApplicationHelper` or any other shared Helper module.
