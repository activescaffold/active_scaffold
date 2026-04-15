---
title: CanCan FAQ
date: "2025-02-17 14:17:02.000000000 +01:00"
permalink: "/wiki-2/cancan-faq/"
---

Q. I get a undefined method 'something\_id' for nil:NilClass
------------------------------------------------------------

**A**. CanCan tries to authorize a model instance not sufficiently wired to it's scope.
For example while authorizing a document it might look for `document.project.owner_id` and if the document does not have a project assigned the error will be rendered.
To fix this override the piece of code (in your controller/view) that deals with the model and make sure to wire it up.
Sample [here](https://gist.github.com/850091)

Q. I get a undefined method 'can?' for nil:NilClass
---------------------------------------------------

**A**. The `current_ability` (just like `current_user`) is available inside models only **during request/response cycle**, because is inserted there by means of a controller before\_filter.
If one queries the CanCan ACL **at configure time** ( when the controller class body executes ) the authorization will find no current ability to query upon.
**At configure time** we have nothing: no `current_user`, no `current_ability`.
You can only query the authorization during request/response when a user is logged in.
One way to deal with this is: since at configure time we know nothing of who we're authorizing, we can return whatever `authorized_for_without_cancan?` returns (default old behavior).
In this case because of the default "paranoic" false security reply (if you use it like this):

```
ActiveScaffold.set_defaults do |config|
  config.security.default_permission = false
end
```
you'll have to override the security methods as per [AS\#security wiki](https://github.com/activescaffold/active_scaffold/wiki/Security)

Q. My form only shows the submit button, all the fields are missing
-------------------------------------------------------------------

**A**. AS also authorizes at column level, and your CanCan rule probably replies "no". Make sure the model (`@record`) that is used for `form_for` is sufficiently wired to it's related objects. For example the rule `can :create, Project, :account_id => user.account_id` will render an empty form for a record unless you wire it (override `do_new` in controller) like `@record.account_id = current_user.account_id`. As a side-note, a better rule in the given example is `can :create, Project` and enforce `@record.account_id = current_user.account_id` in the update action.

Q. I have a n+1 query problem because of this bridge
----------------------------------------------------

**A**. Make sure you eager load either via [Column\#includes](https://github.com/activescaffold/active_scaffold/wiki/API:-Column) or via `active_scaffold_includes` instance method override for corner cases.

Q. I just installed CanCan and all my data vanished
---------------------------------------------------

**A**. Because CanCan plugs into your select conditions, you can only see the records that have "can" rules that allow them. So unless you write `can :read, User` no user shall be showed. Or when you write `can :read, User, :active => true` only active users will be showed.

Q. I get a The accessible\_by call cannot be used with a block 'can' definition error
-------------------------------------------------------------------------------------

**A**. One of your CanCan rules that operate on this model is defined only with block rules. Either modify it to use Hash+block or SQL-Where-fragment+block or (CanCan 1.6) Scope+block, either manually define in your controller the beginning of chain method to skip cancan behavior like so:

```
def beginning_of_chain
  beginning_of_chain_without_cancan.where(your_access_conditions)
end
```
A note of caution
-----------------

Note that this bridge, along with all AS security layer, and probably many parts of ActiveScaffold, is not thread-safe. That means that these features will work bug-free only in a classic Rails shared-nothing deployment architecture. Trying to deploy this in thread-based mode will most probably lead to race conditions and unexpected behavior!
