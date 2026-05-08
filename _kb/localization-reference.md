---
title: "Localization Reference"
category: "Getting Started"
---

## How it Works

ActiveScaffold facilitates localization by using the Object#as_() method:

{% highlight erb -%}
<h4><%= as_('Are you sure?') -%></h4>
{%- endhighlight %}

In the config block ActiveScaffold delays localization until after the session is known, so that you have the chance to know what the target locale should be. Assign the value to the config element:

{% highlight ruby -%}
active_scaffold :event do |config|
  config.create.link.label = 'Create Event'
  config.columns[:address].label = 'Mailing Address'
end
{%- endhighlight %}

and ActiveScaffold will call the Object#as_() method later. You can use symbols in label methods too:

{% highlight ruby -%}
active_scaffold :event do |config|
  config.columns[:address].label = :mailing_address
end
{%- endhighlight %}

Anyway, it's better to use rails localization for model attributes than column.label methods. Localization for model attributes will be used as form labels and in error messages. Use the following structure:

{% highlight yaml -%}
en:
  activerecord:
    models:
      model_name:
        one: "Model in singular"
        other: "Model in plural"
    attributes:
      model_name:
        column_name: "Localized column name"
{%- endhighlight %}

You can use en.yml locale file to customize column and model names instead of using config.label and column.label methods.

## Localization in rails 2.2 or higher

Rails 2.2 now localizes natively the as_() method.  Therefore, your project will need to have a localization file in config/locales/en.yml (This would be the english one.) if locales does not exist, simply create it along with the language yml file.
The yml file could start something like this:

{% highlight yaml -%}
# Sample localization file for English. Add more files in this directory for other locales.
# See https://github.com/svenfuchs/rails-i18n/tree/master/rails%2Flocale for starting points.

en:
  active_scaffold:
    cancel_button_label: "Return to List"
{%- endhighlight %}

The cancel_button_label can be defined at your discrection and used wherever you wish.  It it is important to note you will need to localize your column label overrides in the controller.  Make sure that the yml file contains an entry matching your column label.

Example:

{% highlight ruby -%}
# Controller:
config.column[:company].label = :company_label
{%- endhighlight %}

en.yml:
{% highlight yaml -%}
en:
  active_scaffold:
    company_label: "Company Name"
{%- endhighlight %}

If a key is not translated, as_ will return the unchanged key if it's a string, or titleized key if it's a symbol. So if you don't want to use a locale file, set strings to label methods and ActiveScaffold will keep them unchanged.

## How to Localize ActiveScaffold

Choose a localization plugin or gem. The Ruby on Rails website maintains a nice .rubyonrails.org/rails/pages/InternationalizationComparison of localization options. The .globalize-rails.org/globalize/ and the .gnu.org/software/gettext/ appear to be the most widely adopted options. 

Then override Object#as_() and redirect control to the plugin or gem:

{% highlight ruby -%}
def as_(*args)
  # place custom localization handling here like
  _(*args)
end
{%- endhighlight %}

## Another Option

At one time ActiveScaffold did more than just facilitate localization. When it was decided to remove that code from core, it was captured in the .google.com/p/activescaffoldlocalize/. This plugin localizes all of the ActiveScaffold strings. It also demonstrates a very simple mechanism for localizing your application.
