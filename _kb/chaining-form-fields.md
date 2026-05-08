---
title: "Chaining Form Fields"
category: "Advanced"
---

Sometimes you want update a form field after setting a value in another field.  For example, you might have a form with a dropdown to select an author and another dropdown to select a book, and you want the book dropdown to only display books from the chosen author. To do this, you need to render the books dropdown each time an author is chosen.

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = :book # enables the "magic"
    config.columns[:book].form_ui = :select
  end
end

module UsersHelper
  def options_for_association_conditions(association, record)
    if association.name == :book
      {'books.author_id' => record.author_id}
    else
      super
    end
  end
end
{%- endhighlight %}

The helper code is to show only books belonging to chosen author, as explained in [Custom Association Options](/doc/custom-association-options/).
Chaining form fields works with simple columns and form overrides too, not only with association columns.

You can set an array of columns to update multiple columns when a column changes, and chain column updates:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = [:book, :editorial]
    config.columns[:book].form_ui = :select
    config.columns[:book].update_column = :format
  end
end
{%- endhighlight %}

In this example, fields for book, editorial and format are updated when author changes, and when book changes only format is updated. A form override which use the new author or book must be defined for editorial and format columns, in other case those fields won't change when they will be rendered again.

Usually only the value of the changed column is sent, if you need another values to render the updated columns, enable `send_form_on_update_column` and all the form will be sent.

You can define a controller method named `after_render_field` to change some attributes of current record, so they will be used when rendering the fields. `after_render_field` method gets the record and the changed column:

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = :book
    config.columns[:book].form_ui = :select
    config.columns[:book].update_columns = :format
    config.columns[:format].form_ui = :select
    config.columns[:format].options[:options] = [:a4, :a3]
  end

  protected
  def after_render_field(record, column)
    if column.name == :book
      record.format = record.book.format
    end
  end
end
{%- endhighlight %}

In this example, when book is changed format is updated, using book format as current value.

If you need to send all the form, because you need do some calculations with other fields for example, set `send_form_on_update_column` (added in v2.4). Since v3.2 you can set a selector to send only some fields using `options[:send_form_selector]`

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = [:book, :editorial]
    config.columns[:book].form_ui = :select
    config.columns[:book].update_column = :format
    config.columns[:book].send_form_on_update_column = true
    config.columns[:book].options[:send_form_selector] = '[name*=author],[name*=book]'
  end
end
{%- endhighlight %}

It's possible to change the `form_ui` when the column is being refreshed, even changing between subform (`nil`) and another `form_ui`, for example, changing to `:hidden` to hide a subform or show it depending on other column's value.

{% highlight ruby -%}
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:foreign].form_ui = :checkbox
    config.columns[:foreign_data].form_ui = :hidden
  end

  protected

  def do_edit
    super
    set_foreign_data_ui(@record)
  end

  def after_render_field(record, column)
    set_foreign_data(record) if column == :foreign
  end

  def set_foreign_data(record)
    active_scaffold_config.columns.override(:foreign_data).form_ui = nil if record.foreign
  end
end
{%- endhighlight %}

## Refreshing columns of other model

It's possible to refresh columns of another model displayed in the same form, for example a column in a subform for an association, or a column for the main model when a subform's column is changed. To do it, must use a hash with association's name as key, or the special key `:_root_` to change columns at the top of the form, as explained in the doc for `update_columns` in [API: Column].

For example, in a form for an invoice, having items, it's possible to refresh the tax fields of every item when a value changes in the invoice, and change the invoice's tax summary and total when the tax of an item changes.

When a column uses a hash in `update_columns`, the whole form is needed to know how many items in the subforms are present, but it isn't required to set `send_form_on_update_columns` to true, it will be treated as `true` anyway.

{% highlight ruby -%}
class Invoice < ApplicationRecord
  has_many :items
end

class Item < ApplicationRecord
  belongs_to :tax
end

class InvoicesController < ApplicationController
  active_scaffold :invoice do |conf|
    conf.columns[:state].update_columns = [items: :tax]
  end
end

class InvoicesHelper
  def association_klass_scoped(association, klass, record)
    if association.name == :state
      super.where(state: record.state)
    else
      super
    end
  end
end

class ItemsController < ApplicationController
  active_scaffold :item do |conf|
    conf.columns[:tax].update_columns = [:total, __root__: [:tax_summary, :total]]
  end
end
{%- endhighlight %}

Changing a state in the invoice will refresh the tax fields in all items in the subform, to update the options with the specific tax values for the selected state. And changing the tax in an item, will refresh the item's total (in the subform), and the tax_summary and total of the invoice (at the main form).

If edit form for `Item` is enabled, changing the tax will try to refresh `tax_summary` at the top of the form, but the form is for the `Item` and won't do nothing for `:tax_summary` because there is no such column in `Item`.
    