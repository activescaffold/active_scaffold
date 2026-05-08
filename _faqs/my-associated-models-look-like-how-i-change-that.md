---
title: "My associated models look like #. How can I change that?"
date: "2025-02-17 14:34:47.000000000 +01:00"
---

You want to define a [to_label](/doc/describing-records-to_label) method for your model.

```ruby
class User < ActiveRecord::Base
  def to_label
    "User: #{username}"
  end
end
```
