---
title: "‘has_many :through’ form elements aren’t appearing. Why?"
date: "2025-02-17 14:38:55.000000000 +01:00"
---

Active\_scaffold only shows form elements for write-able attributes. By default in Rails, records of ‘has\_many :through’ associations are read-only. To get around this, simply add ‘:readonly =&gt; false’ to the association (not the join model association), as shown:

```
class Book < ActiveRecord::Base
  has_many :authorships
  has_many :authors, :through => :authorships, :readonly => false
end

class Authorships < ActiveRecord::Base
  belongs_to :book
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :authorships
  has_many :books, :through => :authorships, :readonly => false
end
```
The ‘has\_many :through’ association should now behave just like an HABTM association.
