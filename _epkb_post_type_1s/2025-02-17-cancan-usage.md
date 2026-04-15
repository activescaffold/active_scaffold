---
title: CanCan Usage
date: "2025-02-17 14:09:13.000000000 +01:00"
permalink: "/wiki-2/cancan-usage/"
---

Setup your favourite current\_user strategy (devise, or whatever), and add this to map AS calls (row, show\_search, etc.) to basic ones (create, read, update, delete). Ability\#as\_action\_aliases should be called by the user in his ability class. Note: you can omit this if you want fine control of each action.

```
class Ability < CanCan::Ability
  def initialize(current_user)
    as_action_aliases
  end
end
```
For maximum security, this feature is best used with `default_permission = false`, although `default_permission = true` should also work.

```
# config/initializers/active_scaffold.rb
ActiveScaffold.set_defaults do |config|
  config.security.default_permission = false
end
```
Then, add rules based on role, user, or any other user related method:

```
def initialize(current_user)
    as_action_aliases
    current_user ? user_rules(current_user) : guest_user_rules
    base_rules
  end
def user_rules(user)
   user.roles.each do |role|
      exec_role_rules(role)
   end
   default_user_rules
end
def exec_role_rules( role)
    meth = :"#{role.name}_rules"
    send(meth) if respond_to? meth
  end
def admin_rules
  can :manage, [Article, Post, User, Role]
end
```
Just define your abilities and this bridge will use them automagically, making sure the user sees and does only what he is allowed to do. ActiveScaffold asks CanCan access to the following abilities, grouped in two categories:

1.  CRUD Types `:create, :update, :read`
2.  Actions `:list, :show` etc (other rails actions (controller method names)). Note that NOT ALL the actions in the AS-enabled controller are authorized, but only the actions that are injected by AS as per [AS security documentation](https://github.com/activescaffold/active_scaffold/wiki/Security). The method `as_action_aliases` injected in the Ability class can be called to alias most AS actions to their CRUD corespondent for example list and row to read etc.
```
:TODO document column granularity <https://github.com/vhochstein/active_scaffold/issues#issue/122>
```
For access to be allowed, CanCan must reply true both to `:crud_type` and `:action` simultaneously. If access is not granted it defaults to [old ActiveScaffold security behavior](https://github.com/activescaffold/active_scaffold/wiki/Security) and you can write access rules inside your models like you used to.

The CanCan bridge also makes available to the model the `current_ability` if the model is used within a controller (so this does not work, say, in the console).
