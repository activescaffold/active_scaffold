---
title: "Subform Overrides"
category: "Customization"
---

If you want to customize the form interface for a column in a subform you have two choices: You can define a specially named partial, or you can define a specially named method in your helper file. The difference between the partial and the helper method is that the partial will be responsible for displaying the label and everything, whereas the helper will only be responsible for displaying the input element (or other interface).

These overrides can be used to hide fields on the subform, or even to replace standard inputs with javascript-enabled inputs.

These overrides are currently used by Create and Update.

Overriding the form interface for a subform column follows the same process as for a normal form (See [Form Overrides](/doc/form-overrides/) for more details.) There are a few minor differences however that you need to be aware of.

## Subform Helper Override

The following differences exist between overriding the form interface helper for a subform column that for a normal form column:

1. If you add `clear_helpers` to your ApplicationController, so you don't use all helpers in all controllers, you must include the helper of the subform in the parent controller with `helper :associated_model`. Or you can define the form overrides in UserHelper instead of including the helper in UsersController.
1. You must use the `options` parameter to set the NAME and ID form parameters, otherwise ActiveScaffold will not be able to save the data from your overridden column correctly, and other record can be used to render the field instead of `options[:object]`. Although it's recommended for normal forms too.

Below is an example of overriding the `state_id` column in the ContactInformation subform that is called via the User controller. In this case we want to display a list of names of States, instead of their IDs.

First you setup your classes and their columns (only the columns from ContactInformation are show below):

{% highlight ruby -%}
class User < ActiveRecord::Base
  belongs_to :contact_information
end

class ContactInformation < ActiveRecord::Base
  has_many :users
  belongs_to :state
end

class State < ActiveRecord::Base
  has_many :contact_informations
end

class CreateContactInformations < ActiveRecord::Migration
  def self.up
    create_table :contact_informations do |t|
      t.column :address, :string
      t.column :city, :string
      t.column :state_id, :integer
    end
  end

  def self.down
    drop_table :contact_informations
  end
end
{%- endhighlight %}

Then you setup your column form interface override in your ContactInformationHelper file and include it in UsersController, so the form override will be used in ContactInformation forms and subforms. This override will create a list of all States in the system and display their names, instead of just showing their IDs:

{% highlight ruby -%}
module ContactInformationHelper

  def contact_information_state_id_form_column(record, options)
    collection_select(:record, :state_id, State.find(:all, :order => "name"), :id, :name, {}, options)
  end

end

class UsersController < ApplicationController
  helper :contact_information
  [...]
end
{%- endhighlight %}

Notice the use of `options` in the code above. This is used so right record is used and the name of the column is set correctly in your form element as `record[association_name][column_name]`. Without this the NAME and ID for your column would be set to the current context, and that would of course belong to User (E.g. `record[column_name]`). In such a case ActiveScaffold would try to save the `state_id` form element data to User, and this would fail because `state_id` belongs to ContactInformation.

> Until v2.3 the second argument was only the input name instead of a full options hash. See example below:

{% highlight ruby -%}
module ContactInformationHelper

  # In v2.3 there is no class name prefix
  def state_id_form_column(record, input_name)
    collection_select(:record, :state_id, State.find(:all, :order => "name"), :id, :name, {}, {:name => input_name} )
  end

end
{%- endhighlight %}

## Subform Partial Override (overriding the form element and the label)

The partial override is responsible for displaying the field label, element, description, etc.. It should be named `_#{column_name}_form_column.html.erb` and be placed in the controller's views folder. E.g. In the example above you would place your overriden form partial in `app/views/contact_information/`. In this partial you can put all the custom code you want to use to display the form input element for this column. Follow instructions for usual form partial overrides.

> Until v2.3 the partial override must be placed in the views folder belonging to the controller that called the subform. E.g. In the example above you would place your overriden form partial in `app/views/user/` and not in `app/views/contact_information/`.
