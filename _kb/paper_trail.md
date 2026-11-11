---
title: "PaperTrail"
category: "Integrations"
---

The [PaperTrail](https://github.com/paper-trail-gem/paper_trail) bridge integrates versioned models with ActiveScaffold. For a model using `has_paper_trail`, it adds:

- A `deleted_records` collection action, with a `deleted` link and route, which lists records reified from their destroy versions.
- Support for a nested `versions` member link. The application must provide the `PaperTrail::VersionsController`; ActiveScaffold does not generate it.

## Listing deleted records

The bridge adds `:deleted_records` to the scaffold automatically when its model uses `has_paper_trail`. The `deleted` action queries destroy versions for that model, calls `reify` on them, and renders them with the normal list response. This includes configured API formats such as JSON and XML.

The action is protected by `deleted_authorized?`, which defaults to `list_authorized?`. Override it when access to deleted records should be more restrictive:

{% highlight ruby -%}
class PostsController < ApplicationController
  active_scaffold

  protected

  def deleted_authorized?
    current_user.admin? && super
  end
end
{%- endhighlight %}

The same method controls both the collection link and direct requests to the `deleted` route. Removing or hiding the link is not a substitute for authorization because a client can request the route directly.

### Scoping deleted records

The normal list starts from `beginning_of_chain`, but destroyed records are no longer present in the model's table. Therefore, a tenant or owner scope in `beginning_of_chain` cannot automatically be applied to the deleted-record list. Override `deleted_records_query` in every scaffold where users must only see some destroy versions:

{% highlight ruby -%}
class PostsController < ApplicationController
  active_scaffold

  protected

  def deleted_records_query
    super.where_object(account_id: current_user.account_id)
  end
end
{%- endhighlight %}

`where_object` queries the serialized, pre-destroy attributes in the PaperTrail version's `object` column. It can be used when:

- The version class includes `PaperTrail::VersionConcern`. The standard `PaperTrail::Version` class does.
- The versions table has an `object` column. PaperTrail configurations that omit this column cannot use `where_object` or reify deleted records.
- The attribute used for the scope is stored in `object`; attributes excluded with PaperTrail's `skip` option cannot be queried this way.
- The storage format is supported. PostgreSQL `json` and `jsonb` columns work directly. A text `object` column works with PaperTrail's built-in YAML and JSON serializers; a custom serializer must implement `where_object_condition`.

Checking `respond_to?(:where_object)` only confirms that the version class provides the API. It does not confirm that the `object` column, serializer, or requested attribute supports the query.

For a tenant key queried on every request, a dedicated metadata column on the versions table is generally faster and easier to index than searching `object`. Configure PaperTrail to copy the tenant key into that column, then scope the version relation normally:

{% highlight ruby -%}
# app/models/post.rb
class Post < ApplicationRecord
  has_paper_trail meta: {account_id: :account_id}
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  active_scaffold

  protected

  def deleted_records_query
    super.where(account_id: current_user.account_id)
  end
end
{%- endhighlight %}

Whichever strategy is used, add a request test proving that one tenant cannot retrieve another tenant's deleted records through HTML or an API format.

To disable the deleted-record list for a scaffold, remove `:deleted_records` from its configured actions:

{% highlight ruby -%}
active_scaffold do |config|
  config.actions.exclude :deleted_records
end
{%- endhighlight %}

## Displaying the version history for a record

The bridge can add a nested member link to a PaperTrail version scaffold:

{% highlight ruby -%}
active_scaffold do |config|
  config.nested.add_link :versions
end
{%- endhighlight %}

The application must provide the controller, view, and route. For example:

{% highlight ruby -%}
# app/controllers/paper_trail/versions_controller.rb
class PaperTrail::VersionsController < ApplicationController
  active_scaffold PaperTrail::Version do |config|
    config.actions = %i[list show nested]
  end

  protected

  def do_show
    super
    @record = @record.reify
  end

  def show_authorized?(record = nil)
    record.try(:event) != 'create' && super
  end
end

# config/routes.rb
namespace :paper_trail do
  resources :versions, concerns: :active_scaffold
end
{%- endhighlight %}

{% highlight erb -%}
<%# app/views/paper_trail/versions/_show.html.erb %>
<% extend "#{@record.class.name.pluralize}Helper".constantize rescue nil %>
<%= render :super %>
{%- endhighlight %}
