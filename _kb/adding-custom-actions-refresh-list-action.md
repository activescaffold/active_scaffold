---
title: Adding custom actions Refresh list action
date: "2025-02-17 14:50:43.000000000 +01:00"
permalink: "/wiki-2/adding-custom-actions-refresh-list-action/"
---

One of the easiest actions you can add, is an action which refreshes the list. It could be an action which changes some filtering, for example.

Action links will be rendered inline by default, but you must remember to set :position to false, because your action won't return html code. You can use `:index` action setting a label and some parameters. You can set some conditions in conditions from collection when some parameters are present, or maybe you can set some columns in the parameters and conditions will be added automatically.

 

```
class InvoicesController < ApplicationController
  active_scaffold do |config|
    config.action_links.add :index, :label => 'Show paid', :parameters => {:paid => true}, :position => false
    # it will fiter records with paid set to true
    [more configuration]
  end
end
```
Another way is using a custom action and calling list method after doing your processing. List method will load records for last page you visited, obeying your last search if it's enabled.

```
class InvoicesController < ApplicationController
  active_scaffold do |config|
    config.action_links.add :custom, :position => false
    # it will fiter records with paid set to true
    [more configuration]
  end
  def custom
    flash[:info] = 'custom method called'
    list
  end
end
```
