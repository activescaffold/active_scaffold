---
title: "Preload Column Counts"
category: "Advanced"
---

When associations are not preloaded, setting `includes = nil`, because they are big associations, or only the association's size will be displayed, to avoid running a count query on each row, the counts are preloaded with one count SQL query.

To preload the counts, the `cache_column_counts` method is called in index action, it receives the records set by do_list, and set `@counts`, which is a hash with column names as keys, and counts hash, indexed by record's primary key, as values.

This method uses a query to get the counts on all listed records for an association column, using group, instead of sending a count query for each record, when the column is a collection association and it has no includes defined (`includes = nil`) and it's set to display the number of associated records (`associated_number = true`, enabled by default), and the association has no counter cache. It's useful for associations which have many associated record, and want to display the number without displaying any other info for associated records (`associated_limit = 0`), so there is no need to load any associated record, just the count.

The method gets the columns to preload the counts by calling `columns_to_cache_counts`, which returns an array of columns. Then, for each column, will call `count_query_for_column` to return the query to call count on it for associations on ActiveRecord models, or `mongoid_count_for_column` for associations on Mongoid models, and set the hash with counts per primary key in `@counts` indexed by column's name.

The `count_query_for_column` method can be overrided to change how the query is generated, using other code to generate the query, or calling `super` and changing the returned relation object.

{% highlight ruby -%}
  def count_query_for_column(column, records)
    if column == :tickets
      super.where(created_at: 90.days.ago..Time.now)
    else
      super
    end
  end
{%- endhighlight %}

2 kind of queries can be generated:

* If the association is has many, not using through, not on polymorphic association (no `:as` option) or reverse association is known, then a query on the associated table, without join, is used, grouped by foreign_key, and filtered for the selected records on the foreign key (and model in foreign_type column for polymorphic associations). For example, a model has many alerts, as alertable, so Alarm belongs to alertable, which is polymorphic:
{% highlight ruby -%}
class Model
  has_many :alerts, as: :alertable

class Alarm
  belongs_to :alertable, polymorphic: true
{%- endhighlight %}
The count query will be:
{% highlight sql -%}
SELECT COUNT(*) AS count_all, `alerts`.`record_id` AS alerts_record_id FROM `alerts` WHERE `alerts`.`record_id` IN (3, 19) AND `alerts`.`record_type` = 'Model' GROUP BY `alerts`.`record_id`
{%- endhighlight %}
* If the association is a has_and_belongs_to_many, or has_many using through, or reverse association is polymorphic (has_many using :as option) but is unknown, then will use a query with join, filter records by primary key and group on primary key, e.g.:
{% highlight sql -%}
SELECT COUNT(*) AS count_all, `customers`.`id` AS customers_id FROM `customers` INNER JOIN `invoices` ON `invoices`.`customer_id` = `customers`.`id` INNER JOIN items ON `items`.`invoice_id` = `invoices`.`id` WHERE `customers`.`id` IN (3, 19) GROUP BY `customers`.`id`
{%- endhighlight %}
