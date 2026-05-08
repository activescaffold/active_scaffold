---
title: "Custom Association Options"
category: "Advanced"
---

When ActiveScaffold displays a dropdown on the form of records to associate with the current record (the one being edited or created), it has to decide which records should be present. The default behavior is to display “orphaned” (unassociated) records for :has_one and :has_many associations, and to display all records for :belongs_to and :has_and_belongs_to_many, sorted by to_label method, or whatever is defined in the column's sort_by.

You may want to display all records every time, or you may want to impose extra conditions. The solution is to create a method called `options_for_association_conditions` in your controller’s helper file. This method accepts an AssociationReflection object and current record, and returns SQL conditions (in any of the common formats).

This method is used in association columns with :select form_ui too.

For example, let’s say that you have a UsersController, and that a User has_and_belongs_to_many Roles. Let’s say that you don’t want to show the Admin Role as an option, unless the current user is an Admin. You’ve already got validation set up, but you just don’t want the option in the list. Here’s what you could do:

{% highlight ruby -%}
module UsersHelper
  def options_for_association_conditions(association, record)
    if association.name == :role
      ['roles.id != ?', Role.find_by_name('admin').id] unless current_user.admin?
    else
      super
    end
  end
end
{%- endhighlight %}

Remember that, since this method is a view helper, you can access all the associated controller and views associated methods and variables, including the params; given this, you can easily access the record being edited in the @`record` variable:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = :book
    config.columns[:book].form_ui = :select
  end
end

module UsersHelper
  def options_for_association_conditions(association, record)
    if association.name == :book
      {'books.author_id' => record.author_id}
    else
      super
    end
  end
end
{%- endhighlight %}

If you want to use scopes to get the associated records, you must override `association_klass_scoped` method in your controller’s helper file. This method gets the AssociationReflection object, association class (or selected class for polymorphic associations) and current record. You can invoke super wich return model class or relation, and you can invoke scope methods on it.

{% highlight ruby -%}
class User < ActiveRecord::Base
  scope :with_role, lambda { |role| where(:role => role) }
end

module UsersHelper
  def association_klass_scoped(association, klass, record)
    if association.name == :role
      super.with_role('admin')
    else
      super
    end
  end
end
{%- endhighlight %}

The method used to display the label can be changed in column's options, with :label_method key, passing a symbol with the method's name to use. Options will be sorted by this method too, instead of to_label.

{% highlight ruby -%}
  conf.columns[:role].options[:label_method] = :label_with_extra_data
{%- endhighlight %}

If the column has a SQL sort defined, it will be used to sort the options instead of sorting by the defined label method.

{% highlight ruby -%}
  conf.columns[:role].sort_by sql: ['roles.level', 'roles.name']
{%- endhighlight %}

If sort_by SQL is not defined, the order can be changed overriding the method `sorted_association_options_find`

{% highlight ruby -%}
module UsersHelper
  def sorted_association_options_find(association, conditions = nil, record = nil)
    if association.name == :role
      super.sort_by { |role| [role.level, role.name] }
    else
      super
    end
  end
end
{%- endhighlight %}

## Helpers Prefixed with Model Name

The following methods, `options_for_association_conditions`, `association_klass_scoped` and `sorted_association_options_find`, can be defined with model name prefix, so they are called only with associations for that model. In that case, the method should call the original AS helper instead of super in the else clause.

This is useful when `clear_helpers` is not called in `ApplicationController`, as the same method may be defined in many helper modules, and when some models have associations with the same name, they may need different conditions. Also, it prevents of calling many methods in the different helper modules.

{% highlight ruby -%}
module UsersHelper
  def user_options_for_association_conditions(association, record)
    if association.name == :role
      ['roles.id != ?', Role.find_by_name('admin').id] unless current_user.admin?
    else
      options_for_association_conditions(association, record)
    end
  end

  def user_association_klass_scoped(association, klass, record)
    if association.name == :role
      super.with_role('admin')
    else
      association_klass_scoped(association, klass, record)
    end
  end
end
{%- endhighlight %}

If the association is defined in a STI model, prefixing with the base class is supported too, so subclasses can use a helper override prefixed with own class name, which is specific for the subclass, or share a helper override with the base class name prefix. For example:

{% highlight ruby -%}
class User < ApplicationRecord
  belongs_to :role
end

class Admin < User
end

class Member < User
end
{%- endhighlight %}

Admin will look for `admin_options_for_association_conditions` and `user_options_for_association_conditions`, and Member will look for `member_options_for_association_conditions` and `user_options_for_association_conditions`, so `user_options_for_association_conditions` can be defined if the same conditions applies to both models. This is more useful when `clear_helpers` is not called in `ApplicationController`, or when the method is defined in `ApplicationHelper` or any other shared Helper module.