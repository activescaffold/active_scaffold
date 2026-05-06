---
title: "My associated models look like #. How can I change that?"
date: "2025-02-17 14:34:47.000000000 +01:00"
---

You want to define a <a href="https://github.com/activescaffold/active_scaffold/wiki/Describing-Records%3A-to_label" class="internal present">to_label</a> method for your model.

```
class User < ActiveRecord::Base
  def to_label
    "User: #{username}"
  end
end
```
