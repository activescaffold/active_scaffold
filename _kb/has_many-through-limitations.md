---
title: "has_many : through limitations"
category: "Advanced"
---

### Nested Scaffold Limitations

No special code is needed for has_many :through nested scaffolds, but create can't be used unless the source association is a belongs_to, ActiveRecord can't modify has_many associations with has_one or has_many source, you need to modify the through association directly.

### Subform Limitations

To write

