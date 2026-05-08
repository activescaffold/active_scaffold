---
title: "CanCan"
category: "Integrations"
---

### About

If you use [CanCan](https://github.com/ryanb/cancan) for authorization, the ActiveScaffold CanCan bridge auto-loads and plugs into ActiveScaffold by chaining your Ability rules in the default ActiveScaffold behavior. (Versions AS >= 3.0.13 & CanCan ~> 1.6.7)

**Disclaimer: Test your security setup! If your data is critical and you want complete peace of mind, you must test it yourself. Make sure you have been as specific as possible, and that you have tested to make sure your security methods are being used.**

### Features

1. activates only when CanCan is installed via default bridges `@install_if = lambda { Object.const_defined?(name) }` functionality
2. delegates to [default AS security](/doc/security) in case CanCan says "no"
3. integrates with `beginning_of_chain` both in "list" and "nested" via `CanCan#accessible_by`, feature more known as `load_and_authorize_resources`. This means that the index action will select from the database only allowed records for the current user, and the creation of a record is done on the allowed scope (ie.: `Model.where(restrictions_from_cancan).new`). Note that you must test this, because on some cases, when using MetaWhere or Squeel or scope-based conditions in CanCan rules, not all conditions can be used for creation.

### Usage

Setup your favourite current_user strategy (devise, or whatever), and add this to map AS calls (row, show_search, etc.) to basic ones (create, read, update, delete). Ability#as_action_aliases should be called by the user in his ability class. Note: you can omit this if you want fine control of each action.

{% highlight ruby -%}
class Ability < CanCan::Ability
  def initialize(current_user)
    as_action_aliases
  end
end
{%- endhighlight %}

For maximum security, this feature is best used with `default_permission = false`, although `default_permission = true` should also work.

{% highlight ruby -%}
    # config/initializers/active_scaffold.rb
    ActiveScaffold.set_defaults do |config|
      config.security.default_permission = false
    end
{%- endhighlight %}

Then, add rules based on role, user, or any other user related method:
{% highlight ruby -%}
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
{%- endhighlight %}

Just define your abilities and this bridge will use them automagically, making sure the user sees and does only what he is allowed to do. ActiveScaffold asks CanCan access to the following abilities, grouped in two categories:

1. CRUD Types `:create, :update, :read`
2. Actions `:list, :show` etc (other rails actions (controller method names)). Note that NOT ALL the actions in the AS-enabled controller are authorized, but only the actions that are injected by AS as per [AS security documentation](/doc/security). The method `as_action_aliases` injected in the Ability class can be called to alias most AS actions to their CRUD corespondent for example list and row to read etc.  
:TODO document column granularity [issue #122](https://github.com/vhochstein/active_scaffold/issues/122)

For access to be allowed, CanCan must reply true both to `:crud_type` and `:action` simultaneously.
If access is not granted it defaults to [old ActiveScaffold security behavior](/doc/security) and you can write access rules inside your models like you used to.

The CanCan bridge also makes available to the model the `current_ability` if the model is used within a controller (so this does not work, say, in the console).

### Important

Note that the bridge plugs into `AS#begining_of_chain`. That is the main scope from which the listing is fetched and new models are created. 
The bridge chains this scope taking into account your ability definitions similar to how `CanCan#load_and_authorize_resources` works, by limiting the result according to the Ability definitions.

### FAQ

**Q**. I get a `undefined method 'something_id' for nil:NilClass`  
**A**. CanCan tries to authorize a model instance not sufficiently wired to it's scope.  
For example while authorizing a document it might look for `document.project.owner_id` and if the document does not have a project assigned the error will be rendered.  
To fix this override the piece of code (in your controller/view) that deals with the model and make sure to wire it up.  
Sample [here](https://gist.github.com/850091)

**Q**. I get a `undefined method 'can?' for nil:NilClass`  
**A**. The `current_ability` (just like `current_user`) is available inside models only **during request/response cycle**, because is inserted there by means of a controller before_filter.  
If one queries the CanCan ACL **at configure time** ( when the controller class body executes ) the authorization will find no current ability to query upon.  
**At configure time** we have nothing: no `current_user`, no `current_ability`.  
You can only query the authorization during request/response when a user is logged in.  
One way to deal with this is: since at configure time we know nothing of who we're authorizing, we can return whatever `authorized_for_without_cancan?` returns (default old behavior).  
In this case because of the default "paranoic" false security reply (if you use it like this):  

    ActiveScaffold.set_defaults do |config|
      config.security.default_permission = false
    end

you'll have to override the security methods as per [AS#security  wiki](/doc/security)

**Q**. My form only shows the submit button, all the fields are missing  
**A**. AS also authorizes at column level, and your CanCan rule probably replies "no". Make sure the model (`@record`) that is used for `form_for` is sufficiently wired to it's related objects. For example the rule `can :create, Project, :account_id => user.account_id` will render an empty form for a record unless you wire it (override `do_new` in controller) like `@record.account_id = current_user.account_id`. As a side-note, a better rule in the given example is `can :create, Project` and enforce `@record.account_id = current_user.account_id` in the update action.

**Q**. I have a n+1 query problem because of this bridge  
**A**. Make sure you eager load either via [Column#includes](/doc/api-column) or via `active_scaffold_includes` instance method override for corner cases.  

**Q**. I just installed CanCan and all my data vanished  
**A**. Because CanCan plugs into your select conditions, you can only see the records that have "can" rules that allow them. So unless you write `can :read, User` no user shall be showed. Or when you write `can :read, User, :active => true` only active users will be showed.

**Q**. I get a `The accessible_by call cannot be used with a block 'can' definition` error  
**A**. One of your CanCan rules that operate on this model is defined only with block rules. Either modify it to use Hash+block or SQL-Where-fragment+block or (CanCan 1.6) Scope+block, either manually define in your controller the beginning of chain method to skip cancan behavior like so:

    def beginning_of_chain
      beginning_of_chain_without_cancan.where(your_access_conditions)
    end

### A note of caution

Note that this bridge, along with all AS security layer, and probably many parts of ActiveScaffold, is not thread-safe. That means that these features will work bug-free only in a classic Rails shared-nothing deployment architecture. Trying to deploy this in thread-based mode will most probably lead to race conditions and unexpected behavior!  