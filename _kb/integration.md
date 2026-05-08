---
title: "Integration"
category: "Integrations"
---

ActiveScaffold by itself comes alone so you decide what to use or how to integrate into your solution, allowing to be flexible and avoid dependency problems. Following that approach, there are many gems you can install and ActiveScaffold will integrate them very well out of the box. Note that some of them need some config. So read on: 

## Data handling

- [active scaffold export](https://github.com/naaano/active_scaffold_export) Export to CSV plugin 
- [dragonfly](https://github.com/markevans/dragonfly) Images & files support
- [paperclip](https://github.com/thoughtbot/paperclip) Images & files support
- [carrierwave](https://github.com/jnicklas/carrierwave) Images & files support
- [file_column](https://github.com/tekin/file_column) Images & files support
- [active scaffold batch](https://github.com/activescaffold/active_scaffold_batch) Mass data handling
- [active scaffold duplicate](https://github.com/activescaffold/active_scaffold_duplicate) Clone record gem for Activescaffold
- [paper_trail](/doc/paper_trail/) Track versions and changes

## User Interface

- [Record Select](/doc/record-select-integration/) Fancy select box alternative, with ajax autocomplete. Very suitable for long datasets
- [ancestry](https://github.com/stefankroes/ancestry) Tree structured associations support
- [active scaffold sortable](https://github.com/activescaffold/active_scaffold_sortable) Drag and drop sorting
- [active scaffold config list](https://github.com/activescaffold/active_scaffold_config_list) Adds UI for columns list configuration per user/session
- [active scaffold signaturepad](https://github.com/activescaffold/active_scaffold_signaturepad) Adds UI for signature on touch devices, using [jquery.signaturepad](https://github.com/thomasjbradley/signature-pad)
- [bitfields](https://github.com/grosser/bitfields) Show check boxes for integer bitfields, grouped by bitfield.
- [tiny mce](https://github.com/spohlenz/tinymce-rails) Formatted Text Editor
- [chosen](https://github.com/tsechingho/chosen-rails) Make long, unwieldy select boxes more user friendly

## User & role management / Security

As global user & management integration notes, you need to know that Active Scaffold uses "current_user" method to refer to interacting user in controllers, methods, helpers and views. Devise use the same convention, so you don't have to do anything there. But in case you use another name, say account or just user, remember to set current_user_method in application_controller.rb:

{% highlight ruby -%}
ActiveScaffold.set_defaults do |config|
  config.security.current_user_method = :current_login
end
{%- endhighlight %}

- [CanCan](/doc/cancan/) 
With CanCan you can control most of AS behavior and appearance per user and/or role. Add [cancan as instructed](https://github.com/ryanb/cancan)

- [Declarative Authorization](/doc/security-declarative-authorization/)

- [Devise](https://github.com/plataformatec/devise) 