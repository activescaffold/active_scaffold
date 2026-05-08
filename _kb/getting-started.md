---
title: "Getting Started"
category: "Getting Started"
---

## Installing

To get started with a new Rails project

Added to Gemfile

{% highlight ruby -%}
gem 'active_scaffold'
{%- endhighlight %}

Add jQuery, by adding jquery-rails gem or other ways, `active_scaffold:install` generator will add the lines to load jQuery if jquery-rails gem is available, if using other ways, you must setup to ensure jQuery is loaded before active_scaffold.

Run the following commands:

{% highlight sh -%}
bundle install
rails g active_scaffold:install
rails db:create
rails g active_scaffold:resource User name:string
rails db:migrate
{%- endhighlight %}

Run the app and visit localhost:3000/users

### [Developing on a Mac](https://github.com/activescaffold/active_scaffold/wiki/Rails-6-setup-on-Mac-Catalina-or-BigSur,-with-Brew)

It has some notes to install on a mac, for rails 6, but some tips may apply to newer versions.

### Installing old versions

For Rails < 6.1, see [older versions](https://github.com/activescaffold/active_scaffold/wiki/Getting-Started-Old))

## Your First ActiveScaffold

Use `active_scaffold` or `active_scaffold_controller` generators instead of resource or controller generators in rails 3. They will create controllers with active_scaffold enabled, as well as active_scaffold routes:

{% highlight sh -%}
rails g active_scaffold:resource Model attr1:type attr2:type
rails db:migrate
{%- endhighlight %}

That’s it! Your first ActiveScaffold is up and running.

## Starting to Configure

Your scaffold should be up and running with default everything right now. Not quite how you want it?

First let's introduce the **global** config block. You probably noticed that the active_scaffolding includes everything in the table. Let's remove a few of these columns with one easy config block. Create an `active_scaffold.rb` initializer in `config/initializers`. And don't forget to restart your application whenever you make changes to this file.

{% highlight ruby -%}
# config/initializers/active_scaffold.rb
ActiveScaffold.defaults do |config| 
  config.ignore_columns.add [:created_at, :updated_at, :lock_version]
end
{%- endhighlight %}

It's recommended to call `clear_helpers` in ApplicationController, as some helpers defined by ActiveScaffold, such as active_scaffold_enum_options, options_for_association_conditions, association_klass_scoped, are usually overrided for different controllers, and it may cause issues when all helper modules are available to every controller, specially when models have associations or columns with the same name but need different code for those overrided helper methods.

{% highlight ruby -%}
class ApplicationController < ActionController::Base
  clear_helpers
{%- endhighlight %}

Let's have a look at the **local** config block. This block goes in the model's corresponding controller. The config block for the Company model goes in the CompaniesController. ActiveScaffold restricts one model per controller. Now for an example:

{% highlight ruby -%}
class CompaniesController < ApplicationController

  active_scaffold :company do |config|
    config.label = "Customers"
    config.columns = [:name, :phone, :company_type, :comments]
    list.columns.exclude :comments
    list.sorting = {:name => 'ASC'}
    columns[:phone].label = "Phone #"
    columns[:phone].description = "(Format: ###-###-####)"
  end

end
{%- endhighlight %}

ActiveScaffold tries to be flexible: change the labels, decide which columns to include, control the columns included per-action, define a default sort order, specify a column label and a column description. Check the [API](/doc/api/) docs to see what's possible!