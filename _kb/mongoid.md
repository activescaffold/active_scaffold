---
title: "Mongoid"
category: "Integrations"
---

Basic support has been added for Mongoid, only listing has been tested, other actions may work but they are not supported officially.

Every mongoid document need to include permissions module (ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model) and define to_label method:

{% highlight ruby -%}
class LogLine
  include Mongoid::Document
  include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model

  field :hostname, type: String
  field :message, type: String

  def to_label
    hostname
  end
end
{%- endhighlight %}
