---
title: "Enum Columns"
category: "Advanced"
---

If you use rails enums, you just have to set form_ui to `:select`, and will use the enum options automatically. They will be translated using a nested structure in `activerecord.attributes.<model>`, like the one used by `human_enum_name` gem, for example for status enum with values active and archived:

{% highlight yaml -%}
en:
  activerecord:
    attributes:
      conversation:
        statuses:
          active: Active conversation
          archived: Archived conversation
{%- endhighlight %}

Previously, they were translated as a column name, although it didn't allow to have different translation for the same enum value in multiple enum columns. The old way will be supported too, but nested in pluralized colum name takes precedence. So this way will work too:

{% highlight yaml -%}
en:
  activerecord:
    attributes:
      conversation:
        active: Active conversation
        archived: Archived conversation
{%- endhighlight %}

Also, any other column can be used as an enum with ActiveScaffold.

In create and update actions this will generate a select tag and into list, this will show the translated value. You can set different strings for value and label, for example storing `m` or `f` and showing `male` and `female` in the form and list. ActiveScaffold will translate only symbols, so text to show must be a symbol if you want ActiveScaffold to translate it.


<small>config/locales/en.yml</small>
{% highlight yaml -%}
en:
  activerecord:
    attributes:
      person:
        m: 'Male'
        f: 'Female'
{%- endhighlight %}

{% highlight ruby -%}
# app/models/person.rb
class Person < ActiveRecord::Base
  SEX = %w(m f)
  validates_inclusion_of :sex, :in => SEX
end

# app/controllers/people.rb
class PeopleController < ApplicationController
  active_scaffold do |config|
    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = {:options => Person::SEX.map(&:to_sym)}
  end
end
{%- endhighlight %}

Setting options in config block works for static options. If different options must be used in different requests, because they depend on signed in user or other record's columns, active_scaffold_enum_options helper may be overrided:
{% highlight ruby -%}
# app/helpers/people_helper.rb
module PeopleHelper
  def active_scaffold_enum_options(column, record)
    if column == :sex
      # return array of value, text arrays, or array of symbols
    else
      super
    end
  end
end
{%- endhighlight %}

It can be defined with model name prefix, so it's called only with columns for that model. In that case, the method should call the original AS helper instead of super in the else clause.

This is useful when `clear_helpers` is not called in `ApplicationController`, as the same method may be defined in many helper modules, and when some models have associations with the same name, they may need different conditions. Also, it prevents of calling many methods in the different helper modules.

{% highlight ruby -%}
module PeopleHelper
  def person_active_scaffold_enum_options(column, record, ui_options: ui_options)
    if column == :sex
      # return array of value, text arrays, or array of symbols
    else
      active_scaffold_enum_options(column, record, ui_options: ui_options)
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

Admin will look for `admin_active_scaffold_enum_options` and `user_active_scaffold_enum_options`, and Member will look for `member_active_scaffold_enum_options` and `user_active_scaffold_enum_options`, so `user_active_scaffold_enum_options` can be defined if the same options must be used in both models. This is more useful when `clear_helpers` is not called in `ApplicationController`, or when the method is defined in `ApplicationHelper` or any other shared Helper module.
