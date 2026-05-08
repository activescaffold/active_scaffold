---
title: "Form_ui types"
category: "UI Types"
---

There are different form_ui types in ActiveScaffold, some may be useful for some column types only. The form ui types may use options from column's options hash (`conf.columns[:xxx].options = {...}`), or an options hash set next to the type (`conf.columns[:xxx].form_ui = :yyy, {...}`).

## Basic types

### :boolean

It renders a select box with `true` and `false` options (default for boolean type columns which can be null since v2.4+, previously default for all boolean type columns). If the column can be null, will have `- select -` option (or the label set in `options[:include_blank]`).

![](/assets/screenshots/form-ui-boolean.png)

{% highlight ruby -%}
conf.columns[:approved].form_ui = :boolean, {include_blank: 'Not Set'}
{%- endhighlight %}

![](/assets/screenshots/form-ui-boolean-custom-blank.png)

The options are used for the options argument in `select` rails helper method. Html options argument is read from :html_options key in the options hash.

{% highlight ruby -%}
conf.columns[:is_approved].form_ui = :boolean, {html_options: {title: 'Help on hover'}}
{%- endhighlight %}
{% highlight html -%}
<select name="record[is_approved]" class="is_approved-input" id="record_is_approved_2" title="Help on hover">
{%- endhighlight %}

### :checkbox

It renders a checkbox (default for boolean columns which can't be null since v2.4+)

The options are used for the options argument in `check_box` rails helper method, to set html options in the input tag.

{% highlight ruby -%}
conf.columns[:is_approved].form_ui = :checkbox, {title: 'Help on hover'}
{%- endhighlight %}
{% highlight html -%}
<input type="checkbox" name="record[is_approved]" class="is_approved-input" id="record_is_approved_2" title="Help on hover" value="1" />
{%- endhighlight %}

### :checkboxes

It renders a collection of checkboxes, and can be used with plural associations or database columns, using serialize or defining getter and setter to support saving an array of values. It supports `:draggable_lists` option, as in `:select` UI for plural associations.

### :color

It renders an input with type color, to pick a color. If the column can be null, it renders a checkbox for 'No color' before the input with type color, the text can be changed with :no_color option. Other options are passed to the `color_field` rails helper method.

{% highlight ruby -%}
conf.columns[:background_color].form_ui :color, {no_color: 'Transparent'}
{%- endhighlight %}
![](/assets/screenshots/form-ui-color.png)
![](/assets/screenshots/form-ui-color-nullable.png)


### :date

It renders an input with type date. The options are used as the options argument in `date_field` rails helper method.

{% highlight ruby -%}
conf.columns[:due_on].form_ui = :date, {max: 1.week.since.end_of_week}
{%- endhighlight %}
{% highlight html -%}
<input type="date" name="record[due_on]" class="due_on-input text-input" id="record_due_on_2" max="2024-01-28" />
{%- endhighlight %}

### :datetime

It renders an input with type datetime-local. The options are used as the options argument in `datetime_local_field` rails helper method.

{% highlight ruby -%}
conf.columns[:due_at].form_ui = :datetime, {max: 1.week.since.end_of_week}
{%- endhighlight %}
{% highlight html -%}
<input type="datetime-local" name="record[due_at]" class="due_at-input text-input" id="record_due_at_2" max="2024-01-28T23:59:59" />
{%- endhighlight %}

### :checkboxes

Renders the same UI as `:select` in collection associations, a list of checkboxes supporting to select multiple. The column must support setting an array (for example, using `serialize`, or with custom methods). See explanation for using multiple with non-association columns at [select](/doc/form_ui-types/#select).

### :draggable

It's the same as `:select, {draggable_lists: true}`, for collection associations, see explanation at [select](/doc/form_ui-types/#select). For non-association columns, works like `:checkboxes, {draggable_lists: true}`, but requires serialize or getter and setter.

### :email

It renders input field with type email, in which modern browsers will accept only well-formed email addresses (old browsers will treat it as simple text input). Options are passed as options argument to email_field.

### :month

It renders input field with type month, which modern browsers will render as month picker (old browsers will treat it as simple text input). Options are passed as options argument to month_field.

![](/assets/screenshots/form-ui-month.png)

### :number

It renders input field with type number, in modern browsers will be rendered as spinbox control, that allows only numbers (old browsers will treat it as simple text input). If there is numericality validators in model for that column, the `max`, `min` and `step` attributes will be set automatically, according to them (They can be overriden or manually set in the Column#options hash or ui options hash set next to :number)

{% highlight ruby -%}
conf.columns[:age].form_ui = :number, {min: 18}
{%- endhighlight %}
{% highlight html -%}
<input type="number" name="record[age]" class="age-input numeric-input text-input" id="record_age_" min="18" />
{%- endhighlight %}

### :password

It renders an input with type password. Options are passed as options argument in `password_field` rails helper method, autocomplete defaults to new-password if not set in options hash.

{% highlight ruby -%}
conf.columns[:password].form_ui = :password, {size: 20}
{%- endhighlight %}
{% highlight html -%}
<input type="password" name="record[password]" class="password-input text-input" id="record_password_2" size="20" autocomplete="new-password" />
{%- endhighlight %}

### :radio

Options can be defined in the same way as `:select`, for singular associations or non-association columns. It will use radio buttons instead of select tag.

{% highlight ruby -%}
conf.columns[:level].form_ui =  :radio, {include_blank: 'Not Set', options: ['None', 'Low', 'Medium', 'High', 'Very High']}
{%- endhighlight %}
![](/assets/screenshots/form-ui-radio-options.png)


{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :radio
{%- endhighlight %}
![](/assets/screenshots/form-ui-radio-association.png)

For singular associations, it supports the option `:add_new`, to add a hidden subform to create a new record, when the radio button to create new is selected (it uses a radio button instead of 'Create New' link).

{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :radio, {add_new: true}
{%- endhighlight %}
![](/assets/screenshots/form-ui-radio-add-new.png)

`:add_new` may be a hash with [different options](/doc/options-for-add_new/), as in `:select`.

### :range

It's the same as `:number`, but will be rendered as a slider control.
It renders input field with type range, in modern browsers will be rendered as slider control, that allows only numbers. It works like `:number`, getting options from numericality validators, and accept the same options.

{% highlight ruby -%}
class User < ApplicationRecord
  validates :age, numericality: {greater_than_or_equal_to: 18}
end
class UsersController < ApplicationController
  active_scaffold :user do |conf|
    conf.columns[:age].form_ui = :number, {max: 65}
{%- endhighlight %}
{% highlight html -%}
<input type="range" name="record[age]" class="age-input numeric-input text-input" id="record_age_" min="18" max="65" />
{%- endhighlight %}
![](/assets/screenshots/form-ui-range.png)

### :select

For association columns, it renders a select tag (singular associations) or a collection of checkboxes (plural associations), for other columns, it renders a select tag.

Valid options:
- For columns rendering select tag (singular associations, plural associations when html_options has :multiple key, and non-association columns):
  - options for the select rails method.
{% highlight ruby -%}
conf.columns[:skill].form_ui = :select, {include_blank: 'Pick one'}
{%- endhighlight %}
{% highlight html -%}
<select name="record[skill]" class="skill-input" id="record_skill_">
<option value="">Pick one</option>
</select>
{%- endhighlight %}
  - html options hash under html_options key
{% highlight ruby -%}
config.columns[:category].options = {html_options: {title: 'Select a category to filter skills'}}
{%- endhighlight %}
{% highlight html -%}
<select name="record[category]" class="category-input" id="record_category_" title="Select a category to filter skills">
{%- endhighlight %}
- For associations:
  - :label_method with method name (as symbol) of the model to use instead of :to_label
{% highlight ruby -%}
class User < ApplicationRecord
  belongs_to :skill
  det long_label
    [name, description].compact.join ': '
  end
end

class UsersController < ApplicationController
  active_scaffold :user do |conf|
    conf.columns[:skill].form_ui = :select, {label_method: :long_label} # Will call long_label on Skill records for the text of each option.
{%- endhighlight %}
- For singular associations:
  - the :optgroup in options hash will be used to build a grouped options. If the column is an association, and it has :label_method in its own controller, in column.options, then it will be used instead of to_label to display the group name.
{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :select, {optgroup: :skill_discipline}
{%- endhighlight %}
In SkillSubDisciplinesController:
{% highlight ruby -%}
conf.columns[:skill_discipline].options = {label_method: :short_code}
{%- endhighlight %}
![](/assets/screenshots/search-ui-select-optgroup.png)
  - :add_new to support creating a new record. The value for `:add_new` may be `true` or a hash with [different options](/doc/options-for-add_new/).
{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :select, {add_new: true}
{%- endhighlight %}
![](/assets/screenshots/form-ui-select-add-new-empty.png)
![](/assets/screenshots/form-ui-select-add-new-open.png)
- For plural associations:
  - :draggable_lists to show two lists, one with available options and the other with selected options; users select them with drag and drop instead of checkboxes.
{% highlight ruby -%}
conf.columns[:roles].options = {:draggable_lists => true}
{%- endhighlight %}
![](/assets/screenshots/form-ui-select-draggable.png)
  - :multiple can be set in :html_options, changing to render as select with multiple attribute. It will add `[]` to the select tag name. In this case, plural associations may have options for `select` rails helper method, and html_options, as any column rendering `select` tag.
{% highlight ruby -%}
class User < ApplicationRecord
  has_many :skills
end
class UsersController < ApplicationController
  active_scaffold :user do |conf|
    conf.columns[:skills].options = :select, {html_options: {html: true}}
{%- endhighlight %}
![](/assets/screenshots/search-ui-select-multiple.png)
- For non-association columns:
  - :options hash or nested array under options key
{% highlight ruby -%}
config.columns[:name].options = {:options => [['some text', 'some value'], ['another text', 'another value']]}
{%- endhighlight %}
{% highlight html -%}
<select name="record[name]" class="name-input" id="record_name_">
<option value="some value">some text</option>
<option value="another value">another text</option>
</select>
{%- endhighlight %}
  - :options array under options key, array elements will be used as values and texts, symbols will be translated to use as texts:
{% highlight ruby -%}
config.columns[:name].options = {:options => [:some_value, :another_value]}
{%- endhighlight %}
{% highlight yaml -%}
#translation
en:
  activerecord:
    attributes:
      model_name:
        some_value: "Some translated value"
        another_value: "Another translated value"
{%- endhighlight %}
{% highlight html -%}
<option value="some_value">Some translated value</option>
<option value="another_value">Another translated value</option>
{%- endhighlight %}
  - using :multiple in :html_options, adds multiple attribute to the select tag, as in plural associations. The column must support saving an array, e.g. using serialize in the model.
{% highlight ruby -%}
class User < ApplicationRecord
  serialize :skills
end
class UsersController < ApplicationController
  active_scaffold :user do |conf|
    conf.columns[:skills].options = :select, {options: ['skill 1', 'skill 2', 'skill 3'], html_options: {html: true}}
{%- endhighlight %}
- For every column
  - :refresh_link adds a refresh link, with text refresh and CSS to show an icon, hiding the text. The refresh link triggers render_field request, just as changing an option does when update_columns is enabled. The value can be true, or a Hash with :text option to change the label of the link (although the default CSS hide text and show an icon), and html options for the link.
{% highlight ruby -%}
conf.columns[:skill_sub_discipline].form_ui = :select, {refresh_link: {title: 'Click to reload', text: 'Reload'}}
{%- endhighlight %}
{% highlight html -%}
<select name="record[skill_sub_discipline]" class="skill_sub_discipline-input" id="record_skill_sub_discipline_"><option value="">- select -</option></select>
<a class="refresh-link" title="Click to reload" href="/controller/render_field?column=skill_sub_discipline">Reload</a>
{%- endhighlight %}
![](/assets/screenshots/form-ui-select-refresh-link.png)

### :select_multiple

It works like `:select, {html_options: {multiple: true}}`, to render a select tag with multiple attribute. See explanation at [select](/doc/form_ui-types/#select)

### :telephone

It renders input field with type tel, in which modern browsers will accept only well-formed phone numbers (old browsers will treat it as simple text input). Options are passed as options argument to email_field.

### :textarea

It accepts `:cols`, `:rows` and `:size` options, for the `text_area` rails helper method.

### :time

It renders an input with type time. The options are used as the options argument in `time_field` rails helper method.

{% highlight ruby -%}
conf.columns[:due_at].form_ui = :time, {max: 3.hours.since}
{%- endhighlight %}
{% highlight html -%}
<input type="time" name="record[due_at]" class="due_at-input text-input" id="record_due_at_2" max="11:10:12.317" />
{%- endhighlight %}

### :url

It renders input field with type url, in which modern browsers will accept only well-formed URLs (old browsers will treat it as simple text input). Options are passed as options argument to email_field.

### :week

It renders input field with type week, which modern browsers will render as week picker (old browsers will treat it as simple text input). Options are passed as options argument to week_field.

![](/assets/screenshots/form-ui-week.png)


## Bridge types

### :active_storage_has_many

Added by "active_storage" rails gem, and set by default to ActiveStorage has_many associations (has_many_attached). It renders an input with type file, with multiple attribute, to upload more than one file. When the association has value it shows as the column in the list (if it has more than 3 files then it shows the number of files, otherwise it shows the files), and a link to remove the files, which will show an input file so user can upload other files. It accepts the option `:thumb` with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename.

### :active_storage_has_one

Added by "active_storage" rails gem, and set by default to ActiveStorage has_one associations (has_one_attached). It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. It accepts the option `:thumb` with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename.

{% highlight ruby -%}
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: :thumbnail} # use thumbnail variant
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: {resize: "30x30"}} # display image resized to 30x30
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: false} # display file name
{%- endhighlight %}

![](/assets/screenshots/form-ui-active-storage-empty.png)
![](/assets/screenshots/form-ui-active-storage-file.png)

The default variant can be set with `ActiveScaffold::Bridges::ActiveStorage.thumbnail_variant` in an initializer, which defaults to `{resize_to_limit: [nil, 30]}`. If no thumb option is provided, default value is used from `thumbnail_variant`.

### :ancestry

Added by the gem [ancestry](https://github.com/stefankroes/ancestry.) Set by default in parent_id column of a model using ancestry. It renders a select tag, supporting `:label_method` option as `:select` type.

### :carrierwave

Added by [carrierwave](https://github.com/carrierwaveuploader/carrierwave) gem, and set by default to uploader fields. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. If the mounter has a version it can be used to display an image instead of the filename, it defaults to use :thumbnail version, but can be changed with `ActiveScaffold::Bridges::Carrierwave::CarrierwaveBridgeHelpers.thumbnail_style` in an initializer.

The UI looks similar to the one for `:active_storage_has_one`.

### :chosen

It renders a select using [chosen](https://github.com/tsechingho/chosen-rails) library. It works for the same columns as `:select`, singular and plural associations, or non-association columns. For plural associations accepts options for `select` rails helper method, and html_options in the :html_options key. For other columns, it accepts the same options as `:select` form_ui. You need to add chosen to Gemfile, assets will be added by ActiveScaffold. 

Singular association:
{% highlight ruby -%}
conf.columns[:skill].form_ui = :chosen, {include_blank: 'Select a skill'}
{%- endhighlight %}

![](/assets/screenshots/search-ui-chosen.png)

`:add_new` is supported to create a new record. As in `:select`, the value for `:add_new` may be `true` or a hash with [different options](/doc/options-for-add_new/).

{% highlight ruby -%}
conf.columns[:skill].form_ui = :chosen, {add_new: true}
{%- endhighlight %}

Plural association:
{% highlight ruby -%}
conf.columns[:roles].form_ui = :chosen
{%- endhighlight %}

![](/assets/screenshots/search-ui-chosen-multiple.png)

Column with options:
{% highlight ruby -%}
conf.columns[:level].form_ui =  :chosen, {options: ['Not Set', 'None', 'Low', 'Medium', 'High', 'Very High']}
{%- endhighlight %}

![](/assets/screenshots/search-ui-chosen-with-options.png)

`:optgroup` can be used to group options by another column, as in `:select`:
{% highlight ruby -%}
conf.columns[:skills].form_ui = :chosen, {optgroup: :skill_discipline}
{%- endhighlight %}

![](/assets/screenshots/search-ui-chosen-optgroup.png)

### :country

It requires [country_select](https://github.com/countries/country_select) gem. It accepts `:priority` in the options to set :priority_countries option of `country_select` helper, and `:format`, other options are passed to html_options of `country_select` helper.

{% highlight ruby -%}
    CountrySelect::FORMATS[:with_alpha2] = lambda do |country|
      "#{country.iso_short_name} (#{country.alpha2})"
    end
{%- endhighlight %}
{% highlight ruby -%}
conf.columns[:country].form_ui = :country, {priority: ['US'], format: :with_alpha2, title: 'Select a country'}
{%- endhighlight %}

![](/assets/screenshots/search-ui-country-with-format.png)
![](/assets/screenshots/form-ui-country.png)

### :date_picker

This requires the jquery datepicker, datepicker specific options can be passed via the Column#options hash. When jquery-ui-rails is installed is used for date columns by default. To format input use locale: date.formats.default

### :datetime_picker

The same as date_picker, but with time controls. When jquery-ui-rails is installed is used for datetime columns by default. Format input with locale time.formats.picker

### :dragonfly

It requires the [dragonfly](https://github.com/markevans/dragonfly) gem, when the gem is installed, it's used for dragonfly accessors by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. It accepts the option `:thumb` with a param to pass to `thumb` dragonfly method to be used when displaying the content when the file is an image, if no `:thumb` option is provided, it will use the value defined in `ActiveScaffold::Bridges::Dragonfly::DragonflyBridgeHelpers.thumbnail_style` which defaults to 'x30>'. If the file is not an image, it will display the filename.

{% highlight ruby -%}
conf.columns[:avatar].form_ui = :dragonfly, {thumb: '30x30>'} # use to display a thumbnail
{%- endhighlight %}

The UI looks similar to the one for `:active_storage_has_one`.

### :file_column

This requires the [file_column](https://github.com/tekin/file_column) gem, when the gem is installed, it's used for columns using file_column by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file.

The UI looks similar to the one for `:active_storage_has_one`.

### :paperclip

This requires the [paperclip](https://github.com/thoughtbot/paperclip) gem, when the gem is installed, it's used for paperclip columns by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. If the paperclip column has a style, it can be used to display an image instead of the filename, it defaults to use :thumbnail style, but can be changed with `ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style` in an initializer.

The UI looks similar to the one for `:active_storage_has_one`.

### :record_select

This requires the [recordselect](https://github.com/scambra/recordselect) gem. It renders a text box to search, calling a record_select helper:

- For singular associations, `record_select_field`.
- For plural associations, `record_multi_select_field`.
- For non-association columns, `active_scaffold_record_select_autocomplete`

The next options will be passed to the helper:
- For every column:
  - :params to send to the controller on record select browse and search requests.
- For associations:
  - :controller, must be a string, although it's automatically put to the controller for the associated model, it can be overrided with options.
  - :field_name for the text field, which usually has no name, as RecordSelect submits the id with a hidden field.
- For singular associations:
  - :add_new, to support creating a new record. As in `:select`, the value for `:add_new` may be `true` or a hash with [different options](/doc/options-for-add_new/).
  - :html_options hash with key :multiple, to use `record_multi_select_field` helper instead, other options in the hash are ignored.
- For non-association columns:
  - :controller, must be a string, although it's automatically put to the current controller, may not be useful and it can be set with options.
  - :label with the current value for the record select, instead of getting using the setting in record_select config of the controller

Singular association example:

{% highlight ruby -%}
conf.columns[:task].form_ui = :record_select
{%- endhighlight %}

![](/assets/screenshots/search-ui-record-select.png)


Plural association example:

{% highlight ruby -%}
conf.columns[:tasks].form_ui = :record_select, {params: {endDate: ''}}
{%- endhighlight %}

Add `permit_rs_browse_params` to Helpers so `endDate` param is passed to the search requests issued while typing:

{% highlight ruby -%}
  def permit_rs_browse_params
    [:endDate]
  end
{%- endhighlight %}

![](/assets/screenshots/search-ui-record-select-multiple.png)

Autocomplete on column example, will look on the specified controllers, with the record select config, and selecting a record will copy the label into the text field.

{% highlight ruby -%}
conf.columns[:task_name].form_ui = :record_select, {controller: 'tasks'}
{%- endhighlight %}

![](/assets/screenshots/form-ui-record-select-autocomplete.png)

There are more explanation about [integrating RecordSelect](/doc/record-select/) in the wiki and the [docs for RecordSelect](https://github.com/scambra/recordselect/wiki)

### :text_editor

It can be used as :tinymce too. This requires the tinymce-rails gem for rails >= 3.1 or tiny_mce for rails < 3.1

- TinyMCE supports multiple configuration sets in the config file. The configuration set to use can be set with `:tinymce_config` option, using `:default` if none is set.
{% highlight ruby -%}
active_scaffold :product do |conf|
  conf.columns[:description_html].form_ui = :text_editor, {tinymce_config: :alternate}
end
{%- endhighlight %}

- The default TinyMCE configuration can be modified via the `:tinymce` option hash. Any [configuration options](https://www.tinymce.com/wiki.php/Configuration) that can be passed via the Javascript `tinyMCE.init({ ... })` may be passed as options
{% highlight ruby -%}
active_scaffold :product do |conf|
  conf.columns[:description_html].form_ui = :text_editor, {
    tinymce: {
      theme: '<theme_name>',
      editor_css: '/product_editor.css'
    }
  }
end
{%- endhighlight %}

- Both options `:tinymce_config` and `:tinymce` can be used, selecting the configuration set, and overriding some options.

### :usa_state

It renders select field to choose a USA state. It accepts `:priority` in the options to put at the top some states, and other options accepted by `content_tag` rails helper method.

{% highlight ruby -%}
conf.columns[:state].form_ui = :usa_state, {priority: [%w[Alabama AL], %w[Virginia VA]], title: 'Select a state'}
{%- endhighlight %}

![](/assets/screenshots/form-ui-usa-state.png)
