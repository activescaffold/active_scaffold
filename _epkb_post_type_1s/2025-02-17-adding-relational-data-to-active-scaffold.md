---
title: Adding relational data to Active Scaffold
date: "2025-02-17 15:03:43.000000000 +01:00"
permalink: "/wiki-2/adding-relational-data-to-active-scaffold/"
---

While there is a lot of documentation in the wiki on ActiveScaffold API functions having to do with associations, I couldn't find anything about the basics of showing relational data and enabling creation/editing. After my question on this sat unnoticed for two days on StackOverflow while I was puzzling it out, I thought I'd post this in case it's helpful to others.

In case it makes a difference, this is specifically for ActiveScaffold version 3.3.0.

I'll be using a Customer and Order example below (i.e. a Customer can have multiple Orders, and we want the Customer's name to show in the Order's ActiveScaffold view). The data structure is deliberately kept very simple. Also, I took the "tell them everything" approach with this documentation, so feel free to skip ahead to what you actually need.

First a couple of basic definitions for the below:

-   The **child** table is the table that has the foreign key in it. In the example, Orders will have the foreign key from the Person table.
-   The **parent** table is the table being related to by the child. The Customer table is the parent in the example below.

There are four basic steps to this process.

1.  Set up the relationship in the database.
2.  Set up the relationship in Rails.
3.  Configure ActiveScaffold so it knows what you want to do.
4.  Add a property to the child model that returns the data you want to display in list view.

Here's a walkthrough:

1.  Verify you’ve got a straightforward ActiveScaffold view working for the child. That process is outside the scope of this answer, but see [the Getting Started page](https://github.com/activescaffold/active_scaffold/wiki/Getting-Started) for some straightforward instructions.

2.  Add a foreign key in the **child** table. This requires the creation of the parent and child tables. For editing and creating to work, the foreign key field in the child table **must** be named as the singular form of the parent table with \_id tacked on the end. To complete this, your migration also needs “add\_foreign\_key \[*child table symbol*\], \[*parent table symbol*\]” In the example's case, here’s the full migration:

<!-- -->

```
class CustomerOrderAdd < ActiveRecord::Migration
  def change
    create_table(:customers, primary: :target_group_id) do |t|
      t.column :full_name, :string, null: false
    end
    create_table(:orders, primary: :order_id) do |t|
      t.column :customer_id, :int, null: false
      t.column :order_desc, :string, null: false
    end
    add_foreign_key :orders, :customers
  end
end
```
3. In the parent class, add `has_many *child object symbol plural form*` In our example, this would be:

```
class Customer < ActiveRecord::Base
  has_many :orders
end
```
4. In the child class, add `belongs_to *parent object symbol singular form*` Again in our example, this leads to:

```
class Order < ActiveRecord::Base
  belongs_to :target_group
  . . .
end
```
5. In the child controller’s ActiveScaffold config block, add a column to your ActiveScaffold columns array that will display the related data from the parent class/table. The name of this column **must** be the name of the foreign key column in the child table, minus the \_id at the end (which ends up being the name of the related table). (*edit: I have no idea how you can add multiple columns from the related table with these naming requirements*) In our example, this leads to the addition of `:customer` in the columns array:

```
class OrdersController < ApplicationController
  active_scaffold :order do |config|
    config.label = 'Customer Orders'
    config.list.sorting = [{customer_id: :asc}]
    config.list.per_page = 30
    config.columns = [:id, :order_desc, :customer]
  end
end
```
6. To speed things up a bit, tell ActiveScaffold to load parent table data as soon as possible. In our example, this leads to the following addition to the child controller's ActiveScaffold config area:

```
config.columns[:customer_name].includes = :customer]
```
7. Add a function in your child model named exactly the same as the new column name you added to the ActiveScaffold columns array. In this function, type out the related class/table name with a dot at the end, then the property/column name you want to actually show. In the example, this looks like:

```
def customer_name
  customer.full_name
end
```
8. Hit your ActiveScaffold index view for the child class/table. Your value should now be in place.
