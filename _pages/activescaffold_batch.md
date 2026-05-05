---
layout: page
title: ActiveScaffoldBatch
date: 2025-02-18 10:10:11.000000000 +01:00
permalink: "/plugins/activescaffoldbatch/"
parent: Plugins
nav_order: 4
hero_heading: Batch actions for ActiveScaffold
hero_lead: Perfect for administrative tasks requiring bulk updates or deletions
---

This plugin enables batch actions, allowing users to perform operations on multiple records simultaneously.
Perfect for administrative tasks requiring bulk updates or deletions.

### Description

ActiveScaffoldBatch enables batch actions, allowing users to perform operations on multiple records simultaneously. This is useful for administrative tasks that require bulk updates or deletions, optimizing time and effort for developers.

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_batch'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

It provides 3 actions: `batch_create`, `batch_update` and `batch_delete`.
After installation, you can enable batch processing in your ActiveScaffold configuration adding any of those actions to default actions:

{% highlight ruby -%}
ActiveScaffold.set_defaults do |config|
  config.actions << :batch_update
end
{%- endhighlight %}

Or adding them in your controller:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.actions << :batch_create
  end
end
{%- endhighlight %}

### Example Code

If you want to allow bulk activation of users, you can define a custom action:

{% highlight ruby -%}
class UsersController < ApplicationController
  include ActiveScaffold::Actions::BatchBase

  active_scaffold :user do |config|
    config.action_links.collection.add :batch_activate, label: 'Activate Users',
      confirm: 'Are you sure you want to activate the selected users?',
      parameters: {batch_scope: 'marked'}
  end

  def batch_activate
    batch_action
  end

  protected

  def batch_activate_marked
    activated = 0
    each_marked_record do |record|
      if record.update(active: true)
        record.as_marked = false
        activated += 1
      else
        error_records << record
      end
    end
  end
end
{%- endhighlight %}

[<svg aria-hidden="true" class="e-font-icon-svg e-fab-github" viewBox="0 0 496 512" xmlns="http://www.w3.org/2000/svg"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"></path></svg> Get Plugin](https://github.com/activescaffold/active_scaffold_batch){: .btn .btn-primary}
{: .text-center}
