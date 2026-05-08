---
title: "Describing Records: to_label"
category: "Getting Started"
---

When ActiveScaffold needs to present a string description of a record, it searches through a common list of record properties looking for something that responds. The search set, in order, is: `:to_label`, `:name`, `:label`, `:title`, and finally `:to_s`. So if your schema already has one of those fields, it’ll be automatically used. But you can always define a to_label method to customize the string description.

Example:

{% highlight ruby -%}
class User < ActiveRecord::Base
  # ActiveScaffold will automatically use this name method to describe a 
  # record of this type
  def name
    "#{first_name} #{last_name}"
  end
end

class ForumPost < ActiveRecord::Base
  # Assuming that every Post has a title attribute, ActiveScaffold will 
  #automatically use that to describe a record of this type
end

class Car < ActiveRecord::Base
  # But you can always just define your own to_label method
  def to_label
    "#{first_name} #{last_name}"
  end
end
{%- endhighlight %}
