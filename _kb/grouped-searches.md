---
title: "Grouped Searches"
category: "Advanced"
---

ActiveScaffold support aggregated list by one column using [field search](/doc/api-fieldsearch/).

Define the available columns to group by with `config.field_search.group_options`, which is an array of column names. The values can be symbols of column names, which will display the column’s translated name, or an array of label and column name. Instead of column name, a `#` string can be used, to group by column using SQL function.

{% highlight ruby -%}
config.field_search.group_options = [:customer, [:date_year, 'date#year'], [:date_quarter, 'date#year_quarter'], [:date_month, 'date#year_month'], :payment_method]
{%- endhighlight %}

It will add a column, named active_scaffold_group, to field search form, with the next options:

{% highlight html -%}
<select name="search[active_scaffold_group]" id="search_active_scaffold_group">
<option value="">No group</option>
<option value="customer">Customer</option>
<option value="date#year">Date (year)</option>
<option value="date#year_quarter">Date (quarter)</option>
<option value="date#year_month">Date (month)</option>
<option value="payment_method">Payment method</option>
</select>
{%- endhighlight %}

These keys were added to locale file for the labels of `date#function` options, but string can be used instead of symbol, to skip translation:

{% highlight yaml -%}
en:
  activerecord:
    attributes:
      invoice:
        date_year: Date (year)
        date_quarter: Date (quarter)
        date_month: Date (month)
{%- endhighlight %}

If grouping by a belongs_to association column, it will group by the foreign key column.

Selecting the options like `date#function` will group by date column, using a SQL function, depending on the value set after `#`. The next function names are supported:

* year, will use `year` SQL function.
* month, will use `year` SQL function.
* quarter, will use `year` SQL function.
* year_month, will use `extract(YEAR_MONTH FROM <column>)` SQL function, to return year and month in the format YYYYMM.
* yeqr_quarter, will use `YEAR(<column>) * 10 + QUARTER(<column>)` to return year and quarter in the format YYYYQ.

Any other value requires to override `calculation_for_group_by` to return the sql code to use. The method gets 2 arguments, the column name and the group function, e.g.:

{% highlight ruby -%}
def calculation_for_group_by(column_name, group_function)
  if group_function == 'year_week'
    sql_operator(sql_operator(sql_function('year', column_name), '*', 100), '+', sql_function('extract', sql_operator(Arel::Nodes::SqlLiteral.new('WEEK'), 'FROM', column_name))) # YEAR(column_name) * 100 + EXTRACT(WEEK FROM column_name)
  else
    super
  end
end
{%- endhighlight %}

## Changing the group clause

It's possible to change the group clause defining group_by in a column that is in `grouped_columns`, and will be used instead of the default group clause (column name, or association foreign key) when that column is selected to group by. It's also possible to use a virtual column in `grouped_columns` in this way. The query will select each value in the `group_by` setting as `<column_name>_<index>`.

For example, to group by a column in an associated table, `group_by` can be defined in an association column:

{% highlight ruby -%}
class Skill < ApplicationRecord
  has_many :tag_memberships, as: :taggable, dependent: :destroy
  has_many :tags, through: :tag_memberships
{%- endhighlight %}

{% highlight ruby -%}
class SkillsController < ApplicationController
  active_scaffold do |conf|
    conf.grouped_columns = ['tags#year_month']
    conf.columns[:tags].group_by = 'tag_memberships.created_at'
{%- endhighlight %}

Then the query will include `JOIN tag_memberships` and `JOIN tags`, and will use `GROUP BY tag_memberships.created_at`.

Also, it's possible to include SQL functions, and more than one column in the group clause:

{% highlight ruby -%}
conf.columns[:sam_account_name].group_by = ["left(sam_account_name, 3)", :company]
{%- endhighlight %}

In this case, the SQL will be like `SELECT left(sam_account_name, 3) AS sam_account_name_0, table.company AS sam_account_name_1`, and both values will be joined with ` - `. To change how the values are joined, `read_value_from_record` can be overrided in a helper module.

{% highlight ruby -%}
def read_value_from_record(record, column, join_text = ' - ')
  if column == :sam_account_name
    super record, column, ', '
  else
    super
  end
end
{%- endhighlight %}

## Columns in the list

When doing a group search, the query will load only the group column and the columns defined in `list.columns` which have calculation, no action links. It would look like this:

![image](https://github.com/activescaffold/active_scaffold/assets/20515/988566d5-ee10-4d79-a50d-e67d377eedc9)

The columns to include in the grouped search can be set in `config.field_search.grouped_columns`, but all columns must have calculations.

When the columns in `list.columns` have calculations, the normal list without grouped search will include the footer line with the calculations. To have the footer only in the grouped search, the calculations can be defined in other column not included in `list.columns` and define the columns for grouped search with `config.field_search.grouped_columns`, even using virtual columns and defining `grouped_select` with the column to use in the calculation.

For example, an `Invoice` model which has columns `number`, `customer` (a belongs_to association) and `amount`, can use `grouped_amount` virtual column in the grouped search:

{% highlight ruby -%}
class InvoicesController < ApplicationController
  active_scaffold :invoice do |conf|
    conf.list.columns = [:number, :customer, :amount]
    conf.field_search.group_options = [:customer]
    conf.field_search.grouped_columns = [:grouped_amount]

    conf.columns << :grouped_amount
    conf.columns[:grouped_amount].grouped_select = 'invoices.amount'
    conf.columns[:grouped_amount].calculate = :sum
    conf.columns[:grouped_amount].label = 'Amount'
{%- endhighlight %}

Then the list without grouped search will display number, customer and amount, without a footer with calculations. And a grouped search by customer will select `invoices.customer_id, SUM(invoices.amount)`, and will have a footer with the total sum of amount.

It can be used for count too:

{% highlight ruby -%}
class InvoicesController < ApplicationController
  active_scaffold :invoice do |conf|
    conf.list.columns = [:number, :customer, :amount]
    conf.field_search.group_options = [:customer]
    conf.field_search.grouped_columns = [:grouped_amount, :count]

    conf.columns << :grouped_amount
    conf.columns[:grouped_amount].grouped_select = 'invoices.amount'
    conf.columns[:grouped_amount].calculate = :sum
    conf.columns[:grouped_amount].label = 'Amount'
    conf.columns[:count].grouped_select = 'invoices.id'
    conf.columns[:count].calculate = :count
{%- endhighlight %}

The grouped search by customer will select `invoices.customer_id, SUM(invoices.amount), COUNT(invoices.id)`, and will have a footer with the total sum of amount and the total counted invoices.