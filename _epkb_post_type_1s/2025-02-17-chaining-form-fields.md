---
title: Chaining Form Fields
date: "2025-02-17 14:40:49.000000000 +01:00"
permalink: "/wiki-2/chaining-form-fields/"
---

Sometimes you want update a form field after setting a value in another field. For example, you might have a form with a dropdown to select an author and another dropdown to select a book, and you want the book dropdown to only display books from the chosen author. To do this, you need to render the books dropdown each time an author is chosen.

This documentation is for v3.0. In v2.4+ the api is at singular like so:

```
config.columns[:author].update_column = [:col1, :col2]

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
```
In v2.3 you could use @options\[:update\_column\] although it was deprecated and removed in v2.4

```
config.columns[:author].options[:update_column] = :book
```
The helper code is to show only books belonging to chosen author, as explained in [Custom Association Options](https://github.com/activescaffold/active_scaffold/wiki/Custom-Association-Options).
Chaining form fields works with simple columns and form overrides too, not only with association columns.

You can set an array of columns to update multiple columns when a column changes, and chain column updates:

```
class UsersController < ApplicationController
  active_scaffold do |config|
    config.columns[:author].form_ui = :select
    config.columns[:author].update_columns = [:book, :editorial]
    config.columns[:book].form_ui = :select
    config.columns[:book].update_column = :format
  end
end
```
In this example, fields for book, editorial and format are updated when author changes, and when book changes only format is updated. A form override which use the new author or book must be defined for editorial and format columns, in other case those fields won’t change when they will be rendered again.

Usually only the value of the changed column is sent, if you need another values to render the updated columns, enable `send_form_on_update_column` and all the form will be sent.

You can define a controller method named `after_render_field` to change some attributes of current record, so they will be used when rendering the fields. `after_render_field` method gets the record and the changed column:

```
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
```
In this example, when book is changed format is updated, using book format as current value.

If you need to send all the form, because you need do some calculations with other fields for example, set `send_form_on_update_column` (added in v2.4). Since v3.2 you can set a selector to send only some fields using `options[:send_form_selector]`

```
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
```
