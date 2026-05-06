---
title: Adding custom actions Process and refresh action
date: "2025-02-17 14:55:37.000000000 +01:00"
permalink: "/wiki-2/adding-custom-actions-process-and-refresh-action/"
---

It could be an action which acts over some marked records, or a record action. It's like delete action, which doesn't display a form and then do some processing. For a collection action it will refresh the list, for a member action it will refresh row and messages, and calculations if are used.

You must remember to set :position to false too, because your action won't return html code. You should set method to :put, because you will change some records, and :crud\_type if you want to do security checks with that.

On the other hand, you should use `process_action_link_action` method in your action. This method has two optional arguments:

1.  A name to override default responses (`action_update`). If you set this argument, you will have to define `<name>_respond_to_<format>` method for each format you want to respond.
2.  The crud\_type to check security when loading the record. By default it will try to guess it.

Don't forget to set sucessful to true if all goes right.

```
class InvoicesController < ApplicationController
  active_scaffold do |config|
    config.action_links.add :paid, :type => :member, :crud_type => :update, :method => :put, :position => false
    [more configuration]
  end
  def paid
    process_action_link_action do |record|
      if (self.successful = record.paid!)
        flash[:info] = as_(:invoce_paid)
      else
        flash[:error] = as_(:invoce_cannot_be_paid)
      end
    end
  end
end
```
If you want to process each record in last visited page you can use `each_record_in_page` iterator. If you want to process all records, obeying search and custom conditions (conditions from params, conditions\_from\_collection, constraints and so on) you can use `each_record_in_scope` iterator. We will use a collection action in these cases.

```
class InvoicesController < ApplicationController
  active_scaffold do |config|
    config.action_links.add :paid, :type => :collection, :method => :put, :position => false
    [more configuration]
  end
  def paid
    process_action_link_action do
      self.successful = true
      each_record_in_page { |record| record.paid! }
    end
  end
end
```
