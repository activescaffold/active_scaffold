---
title: "Embedded Scaffolds"
category: "Advanced"
---

Embedding scaffolds allow you to reuse your scaffold and insert it into other views as a widget.  You can specify constraints for your scaffold to limit the records it works with.

### Rendering

To embed a scaffold in another controller, or on a page somewhere, use `render :active_scaffold => "controller_id"` (it’s a special call that will turn around and call render_component). You may pass ANY combination of parameters you would like: label, sort, sort_direction, search, and even constraints (covered later).

{% highlight ruby -%}
# Render UsersController.
render :active_scaffold => "users"

# The same, but this time change the heading to "Active Users".
render :active_scaffold => "users", :label => "Active Users"

# Sorting by `name`, ascending. Both :sort and :sort_direction are compulsory.
render :active_scaffold => "users", :params => {:sort => "name", :sort_direction => "ASC"}
{%- endhighlight %}

### Constraints

Constraints are simple field/value pairs used as search conditions for the scaffold’s list. Because constrained columns become rather boring to look at, they are automatically removed from column sets so they don’t appear in List, Create, Update, etc. Furthermore, records created through a constrained embedded scaffold will automatically receive the values it is constrained to (a user can not create a record with a value outside of the constraint). Constraints may be the name of a database field (e.g. user_id) or the name of a attribute or association column. If the constraint is the name of an association, then the constraint value will be assumed an ID.

{% highlight ruby -%}
#render all entries for a user
render :active_scaffold => 'entries', :constraints => { :user_id => @user.id }

#render all active users
render :active_scaffold => 'users', :constraints => { :status => "active" }
{%- endhighlight %}

<b>Important:</b> Constraints are stored in the session. You should therefore only use simple
values, e.g. `record.id instead of `record.

{% highlight ruby -%}
render :active_scaffold => 'users', :constraints => {:active => 1, :user_group => 15},
       :params => {:hello => 'world'}, :label => 'Active Editors'
{%- endhighlight %}

Here's the constraint for a HABTM association.

{% highlight ruby -%}
render :active_scaffold => 'users', :constraints => {:editors => @record.id},
       :label => 'Related Editors'
{%- endhighlight %}

### Advanced: Accessing constraint data in your controller

To access constraint data inside of your controller, use `active_scaffold_session_storage[:constraints][:constraint_key]`.

{% highlight ruby -%}
class Admin::RentalCompsController < ApplicationController
  layout 'default_scaffold'
  before_filter :load_listing

  active_scaffold :rental_comps do |config|
  end

  def load_listing  
    begin
      @listing = Listing.find(active_scaffold_session_storage[:constraints][:listing_id])
    rescue
      @listing = Listing.new
    end
  end

  def before_create_save(record)
    record.listing_id = @listing.id if @listing.id
  end
end
{%- endhighlight %}

At the time of writing, active_scaffold_session is only accessible by the controller, and not by the view.

### Conditions v1.1

Constraints are powerful, but only because they’re limited to equality-based conditions, i.e. a equals b. If you want something simpler and more flexible, add :conditions to your embedded scaffold. Unlike constraints, these conditions will affect what is in the list, but will not affect visible columns and will not automatically apply to all new records. But in exchange you can create greater-than, less-than, in-set, etc., conditions.

{% highlight ruby -%}
#note: example hasn't been tested for typos or other obvious problems
render :active_scaffold => 'users', :conditions => ['created_at > ?', Time.now - 5.days],
       :label => 'New Users'
{%- endhighlight %}

### A Real world Example

The following example comes from a real estate site that lists houses (a `listing`). One page embeds two interfaces on a `listing` page to add the ability to modify/update comparable properties (right there on the same page).

{% highlight ruby -%}
# Here's everything you need to know about the models/controllers involved

# app/models/comp.rb
class Comp < ActiveRecord::Base
  belongs_to :listing
end

# app/models/rental_comp.rb
class RentalComp < ActiveRecord::Base
  belongs_to :listing
end

# app/models/listing.rb
class Listing < ActiveRecord::Base
  has_many :comps
  has_many :rental_comps
end

# app/controllers/admin/comps_controller.rb
class Admin::CompsController < ApplicationController
  layout 'default_scaffold'

  active_scaffold :comp do |config|
    config.columns = [ :listing, :mls, :price, :sqft, :year_built, :basement,
                       :basement_percent, :beds, :baths, :layout, :zip, :status, :rank ]
    columns[:basement].label = "B"
    columns[:year_built].label ="Year"
    columns[:basement_percent].label = "FIN"
    columns[:mls].label = "MLS #"
    columns[:layout].label = "Style"
  end
end

# app/controllers/admin/rental_comps_controller.rb
class Admin::RentalCompsController < ApplicationController
  layout 'default_scaffold'

  active_scaffold :rental_comps do |config|
    config.columns = [ :listing, :monthly_rent_price, :sqft, :zip ]
  end
end
{%- endhighlight %}

<small>app/views/listings/_edit_comps.rhtml</small>
{% highlight erb -%}
<!-- render both scaffolds for the current listing (@listing): -->
<h1>Comps</h1>
<div>
  <%= render  :active_scaffold => "admin/comps",
              :constraints => { :listing_id => @listing.id } %>

  <%= render  :active_scaffold => "admin/rental_comps",
              :constraints => { :listing_id => @listing.id } %>
</div>
{%- endhighlight %}

### Restrictions on embedding scaffolds

You can put the same scaffold more than once on a page, but the constraints or conditions must be different so DOM IDs for the two scaffolds are different.

Do it like this:
{% highlight erb -%}
<div>
  <%= render  :active_scaffold => "admin/comps",
              :constraints => { :status => "active", :listing_id => @listing.id },
              :label => "Active Comps" %>

  <%= render  :active_scaffold => "admin/comps",
              :constraints => { :status => "sold", :listing_id => @listing.id },
              :label => "Sold Comps" %>
</div>
{%- endhighlight %}

### Conclusion

Embedding scaffolds is a great way to re-use interfaces! Be creative, have fun!

## Polymorphic relationships

Polymorphic relationships require a type field.  You should take advantage of this in your embedded scaffolds for these polymorphic relationships by adding the _type field to the constraints of the scaffold.

Example:

Models would look like this:
{% highlight ruby -%}
class Notes < ActiveRecord::Base
  belongs_to :notable, :polymorphic => true
end
class Order < ActiveRecord::Base
  has_many :notes, :as => :notable
end
{%- endhighlight %}

The Notes table in your database would contain among others, the two following fields:
- notable_id
- notable_type

The embeded scaffold in the view:
{% highlight erb -%}
<%= render :active_scaffold => 'order_notes', :constraints => { :notable_id => @record.id, :notable_type => "Order"},
           :label => as_('order_notes_controller_label') %>
{%- endhighlight %}

### Notes

Rails 3.1 can use render_component for embedded scaffolds, but it's not needed and it's untested. You can install vhochstein's gem:
{% highlight shell -%}
gem install render_component_vho
{%- endhighlight %}
