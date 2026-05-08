---
title: "API: Action Columns"
category: "API Reference"
---

`ActionColumns` is the object holding the columns for an action, so it's the value in `create.columns`, `list.columns` and so on. They can have subgroups, which are represented with a nested ActionColumns object, so the subgroups have the same methods too. Also, it's posible to create new objects for custom actions and pass them to `base_form` partial, with `active_scaffold_config.build_action_columns`.

## Attributes

The following attributes can be read and written:

### action

It refers back to the action holding these columns. It's used to get the `crud_type` of the action when iterating, to filter columns based on permissions.

### collapsed

If the group defaults to be displayed in collapsed status (only the group's label is visible). Defaults to false (uncollapsed).

### constraint_columns

It's not actually an attribute because it uses RequestStore so it's reset on every request. Holds the list of constrained columns, e.g. when loading an embedded scaffold.

### css_class (read only)

Used in the subgroups as a class for the tag with `.sub-section` class. It's the underscored label, replacing any characters that are not valid in an HTML class name with a dash (-), ensuring the resulting string is safe to use as a CSS class. For example, `User's permissions` is converted to `user-s-permissions`.

### label

The label to display to the user, it can be a String or a Symbol to be translated, in the `:active_scaffold` scope. Only the label of subgroups is displayed to the user.

### layout

By default it's nil, and all columns are rendered vertically in a column (in forms and show action). It can be changed to `:multiple` to arrange the columns in multiple columns, in this case the existing columns will be moved to the first group of columns (index 0). Then, the ActionColumns object is changed to hold an array of ActionColumns objects, each one is a column in the layout, so they support the same methods. You can use `[index]` to access these layout columns, and new columns are added to the layout adding an array, or using `[index]=`.

### tabbed_by

It's used to build a group of columns with tabs. The columns in the group must be associations, and the tab will be a common column of the associations, which is set in this attribute. The common column can be an association too. It's possible that some associations in the group don't have this column, but have it with a different name and compatible value (singular association or column with the same type), and these columns will need to use `options[:tabbed_by]`.

### unauthorized_columns

It's not actually an attribute because it uses RequestStore, so it's reset on every request. Holds the list of skipped columns when `skip_column?` method is called.

## Methods

It includes the `Enumerable` module, so methods from `Enumerable` are available too.

### []

When layout is `:single` (or nil), it return the column which matches the name.
When layout is `:multiple`, the index must be a number and will return the group of columns at the specified index in the multi-column layout.

### []=

Assigns or updates a group of action columns at a specific index. It's only available when the layout is set to `:multiple`; otherwise, an error is raised. Also, it raises an ArgumentError if the given index is greater than the current number of groups.

If index equals the current size, then a new group is created with the given columns and appended to the collection, adding a new column to the layout. If index is within range of existing groups of columns, the existing group at that index is replaced with the provided columns.

{% highlight ruby -%}
conf.create.columns.layout = :multiple
conf.create.columns[0] = [:email] # changes the first group of columns
conf.create.columns[1] = [:first_name, :last_name] # adds a new group of columns
conf.create.columns[0] # => [:email]
conf.create.columns[1] # => [:first_name, :last_name]
{%- endhighlight %}

### add (aliased as `<<`)

Adds one or multiple column to the ActionColumns object, so the argument is a list of columns (or array when using `<<`):

{% highlight ruby -%}
conf.create.columns.add :first_name, :last_name
conf.create.columns << [:first_name, :last_name]
{%- endhighlight %}

If the layout is set to `:multiple`, then will add a new ActionColumns object with the passed columns:

{% highlight ruby -%}
conf.create.columns.layout = :multiple
conf.create.columns << :email # adds a new group of columns to the multi-column layout, with one column only
conf.create.columns << [:first_name, :last_name] # adds a new group of columns to the multi-column layout
conf.create.columns[0] # => the columns before converting to layout multiple.
conf.create.columns[1] # => [:email]
conf.create.columns[2] # => [:first_name, :last_name]
{%- endhighlight %}

### add_subgroup

Adds a subgroup, receives the label of the subgroup and a block with an argument, the subgroup object, to set the columns and other attributes such as collapsed.

{% highlight ruby -%}
config.create.columns.add_subgroup 'Info' do |group|
  group << [:first_name, :last_name]
  group.collapsed = true
end
{%- endhighlight %}

### each_column

It can be used to iterate over the columns, so the block receives the column or subgroup of columns instead of the column name or subgroup of columns, as it would happen with `each` method. It will check the permissions for the column calling `skip_column?` with the column name and the options hash.

Also, accepts a hash of options:

* flatten: so the block is called only with columns, when a subgroup is found, `each_column` is called on the subgroup with the same options.
* skip_groups: subgroup of columns are skipped and the block is not called for them
* skip_authorization: skip checking permission with `skip_column?`
* for: passed to `skip_column?`, it can be used to check the permissions in a model instance instead of the class. If not set, defaults to the current model.
* core_columns: used to get the column object which is passed into the block, defaults to the `active_scaffold_config.columns`.

### include?

It returns true if the column is included, checking the subgroups too.

### skip_column?

It receives the column name, and a hash of options, `for` key is mandatory, it should be a model class or model instance.

It checks if the column is authorized for the action's crud type, it calls `authorized_for?` method in `options[:for]`, passing the `:action` from the options hash, `crud_type` from the options hash (defaults to the action's crud type), and `column` to the passed column name.

Returns true for columns included in `constraint_columns`, so they are always skipped.

When a column is not authorized, returns true and adds the column to `unauthorized_columns`.

### to_a

Returns the column names and subgroups.

### visible_columns

Returns an array of columns which are authorized, accepts an options hash as `each_column`, it may have different behaviours depending on the options:

* By default will include the subgroups too, but authorization is not checked for the columns in the subgroups.
* When `flatten` is set, it will be an array of columns only, including the columns in the subgroups which are authorized.
* When `skip_groups` is set, won't return the subgroups.
* When `skip_authorization` is set, will return all columns, without checking authorization.

### visible_columns_names

Returns an array of column names which are authorized, accepts an options hash as `each_column`. Defaults to `flatten`.
