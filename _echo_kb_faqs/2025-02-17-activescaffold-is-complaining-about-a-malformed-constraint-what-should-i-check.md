---
title: "ActiveScaffold is complaining about a Malformed Constraint. What should I check?"
date: "2025-02-17 14:35:59.000000000 +01:00"
---

If you are noticing this when trying to open a nested scaffold, the first thing to check is that you have your associations set up in both directions. For instance, if a UserGroup has\_many Users, then make sure that a User belongs\_to a UserGroup. If that doesn’t fix your problem then take another look at your associations – is there a clear “reverse” association? For example, consider the following setup:

```
class Project < ActiveRecord::Base
  has_many :projects_users
  has_many :administrators, :through => :projects_users, :source => :user, :conditions => "projects_users.role_type = 3"
  has_many :managers, :through => :projects_users, :source => :user, :conditions => "projects_users.role_type = 2"
  has_many :workers, :through => :projects_users, :source => :user, :conditions => "projects_users.role_type = 1"
end

class User < ActiveRecord::Base
  belongs_to :organization
  has_many :projects_users
  has_many :projects, :through => :projects_users, :source => :project
end
```
This setup may not work as well when ActiveScaffold is trying to nest Projects for a given User. In order to nest successfully, ActiveScaffold needs to know what the reverse association is. In this case the Project doesn’t have a clear single link to the User model – it has three specialized associations. To remedy the situation, you should add:

```
class Project < ActiveRecord::Base
  has_many :users, :through => :projects_users, :source => :user
  ...
end
```
