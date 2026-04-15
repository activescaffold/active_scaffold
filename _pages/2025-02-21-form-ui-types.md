---
layout: page
title: Form UI Types
date: 2025-02-21 14:46:04.000000000 +01:00
permalink: "/doc/form-ui-types/"
parent: Doc
---

There are different form\_ui types in ActiveScaffold, some may be useful for some column types only. The form ui types may use options from column’s options hash (`conf.columns[:xxx].options = {...}`), or an options hash set next to the type (`conf.columns[:xxx].form_ui = :yyy, {...}`).

### Description

Form UI bridges extend ActiveScaffold by adding support for additional form input types. These bridges integrate with external gems, enabling advanced form elements beyond the default field types provided by ActiveScaffold. This allows seamless integration of external components such as WYSIWYG editors, file uploaders, and complex input fields.

### Installation

Form UI bridges are included in ActiveScaffold and are automatically activated when the required gem is installed. To use a specific Form UI type, ensure the corresponding gem is added to your `Gemfile`:

```
gem 'paperclip'
gem 'tinymce-rails'
```
Then run:

```
bundle install
```

### Usage & Options

To specify a Form UI type for a field, define it in your ActiveScaffold configuration:

```
class ProductsController < ApplicationController
  active_scaffold :product do |config|
    config.columns[:description].form_ui = :text_editor
    config.columns[:image].form_ui = :paperclip
  end
end
```
### Basic types

:boolean

It renders a select box with `true` and `false` options (default for boolean type columns which can be null since v2.4+, previously default for all boolean type columns). If the column can be null, will have `- select -` option (or the label set in options\[:include\_blank\])

<img src="{{site.baseurl}}/assets/2025/02/true.png" width="81" height="79" />

```
conf.columns[:approved].form_ui = :boolean, {include_blank: 'Not Set'}
```
<img src="{{site.baseurl}}/assets/2025/02/298306535-49672a8a-af1f-48be-8077-02be62bb45ac.png" width="108" height="104" />

The options are used for the options argument in `select` rails helper method. Html options argument is read from :html\_options key in the options hash.

```
conf.columns[:is_approved].form_ui = :boolean, {html_options: {title: 'Help on hover'}}

<select name="record[is_approved]" id="record_is_approved_2" title="Help on hover">
```
:checkbox

It renders a checkbox (default for boolean columns which can’t be null since v2.4+)

The options are used for the options argument in `check_box` rails helper method, to set html options in the input tag.

```
conf.columns[:is_approved].form_ui = :checkbox, {title: 'Help on hover'}



<input type="checkbox" name="record[is_approved]" id="record_is_approved_2" title="Help on hover" value="1" />
```
:color

It renders an input with type color, to pick a color. If the column can be null, it renders a checkbox for ‘No color’ before the input with type color, the text can be changed with :no\_color option. Other options are passed to the `color_field` rails helper method.

```
conf.columns[:background_color].form_ui :color, {no_color: 'Transparent'}
```
<img src="{{site.baseurl}}/assets/2025/02/transparente.png" width="148" height="32" />

<img src="{{site.baseurl}}/assets/2025/02/selector-color-300x262.png" width="300" height="262" />

:date

It renders an input with type date. The options are used as the options argument in `date_field` rails helper method.

```
conf.columns[:due_on].form_ui = :date, {max: 1.week.since.end_of_week}



<input type="date" name="record[due_on]" id="record_due_on_2" max="2024-01-28" />
```
:datetime

-   It renders an input with type datetime-local. The options are used as the options argument in `datetime_local_field` rails helper method.

        conf.columns[:due_at].form_ui = :datetime, {max: 1.week.since.end_of_week}

     

        <input type="datetime-local" name="record[due_at]" id="record_due_at_2" max="2024-01-28T23:59:59" />

      

:draggable

It’s the same as `:select, {draggable_lists: true}`, for plural associations, see explanation at [select](https://github.com/activescaffold/active_scaffold/wiki/Form_ui-types#select).

:email

It renders input field with type email, in which modern browsers will accept only well-formed email addresses (old browsers will treat it as simple text input). Options are passed as options argument to email\_field.

:month

It renders input field with type month, which modern browsers will render as month picker (old browsers will treat it as simple text input). Options are passed as options argument to month\_field.

<img src="{{site.baseurl}}/assets/2025/02/298701926-afe80c1b-9c7f-4ad3-b213-77757f2e9623.png" width="235" height="226" />

:number

It renders input field with type number, in modern browsers will be rendered as spinbox control, that allows only numbers (old browsers will treat it as simple text input). If there is numericality validators in model for that column, the `max`, `min` and `step` attributes will be set automatically, according to them (They can be overriden or manually set in the Column\#options hash or ui options hash set next to :number)

```
conf.columns[:age].form_ui = :number, {min: 18}



<input type="number" name="record[age]" id="record_age_" min="18" />
```
:password

It renders an input with type password. Options are passed as options argument in `password_field` rails helper method, autocomplete defaults to new-password if not set in options hash.

```
conf.columns[:password].form_ui = :password, {size: 20}
```
###  

```
<input type="password" name="record[password]" id="record_password_2" size="20" autocomplete="new-password" />
```
:radio

Options can be defined in the same way as `:select`, for singular associations or non-association columns. It will use radio buttons instead of select tag

```
conf.columns[:level].form_ui =  :radio, {include_blank: 'Not Set', options: ['None', 'Low', 'Medium', 'High', 'Very High']}
```
<img src="{{site.baseurl}}/assets/2025/02/298422437-6b1a62b9-19d4-47b1-b1cf-578de7a31801-300x36.png" width="300" height="36" />![]({{site.baseurl}}/assets/2025/02/298422437-6b1a62b9-19d4-47b1-b1cf-578de7a31801.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDAzODcwNzYsIm5iZiI6MTc0MDM4Njc3NiwicGF0aCI6Ii8yMDUxNS8yOTg0MjI0MzctNmIxYTYyYjktMTlkNC00N2IxLWIxY2YtNTc4ZGU3YTMxODAxLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAyMjQlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMjI0VDA4NDYxNlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWIzODIxYjBhMmRhODY3MTI5NjM2YzQ0ZTM3NjA4ZDljMGI3OGU1MDQ1MmU2MzU4NjY5NzgxOTc3NjVkYWYyM2UmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.xnmxNHYOrFILVvJuBBQi3w2LImj2oqTqrHxCwp-qY9Y)

```
conf.columns[:skill_sub_discipline].form_ui = :radio
```
<img src="{{site.baseurl}}/assets/2025/02/298422173-82951183-dad8-4a7e-942c-29e72015a3cc-300x22.png" width="300" height="22" />

For singular associations, it supports the option `:add_new`, to add a hidden subform to create a new record, when the radio button to create new is selected (it uses a radio button instead of ‘Create New’ link).

```
conf.columns[:skill_sub_discipline].form_ui = :radio, {add_new: true}
```
`:layout` and `:hide_subgroups` are supported in the same way as in `:select`.

 
:range

It’s the same as `:number`, but will be rendered as a slider control.
It renders input field with type range, in modern browsers will be rendered as slider control, that allows only numbers. It works like `:number`, getting options from numericality validators, and accept the same options.

```
class User < ApplicationRecord
  validates :age, numericality: {greater_than_or_equal_to: 18}
end
class UsersController < ApplicationController
  active_scaffold :user do |conf|
    conf.columns[:age].form_ui = :number, {max: 65}



<input type="range" name="record[age]" id="record_age_" min="18" max="65" />
```
<img src="{{site.baseurl}}/assets/2025/02/298694823-c385de82-b5ca-4659-8447-93d603f5b0ac.png" width="155" height="31" />

 
:select

For association columns, it renders a select tag (singular associations) or a collection of checkboxes (plural associations), for other columns, it renders a select tag.

Valid options:

-   For columns rendering select tag (singular associations, plural associations when `html_options` has `:multiple` key, and non-association columns):
    -   options for the select rails method.
```
        conf.columns[:skill].form_ui = :select, {include_blank: 'Pick one'}
```
     
```
        <select name="record[skill]" id="record_skill_">
        <option value="">Pick one</option>
        </select>
```
     

    -   html options hash under `html_options` key
```
        config.columns[:category].options = {html_options: {title: 'Select a category to filter skills'}}
```
     
```
        <select name="record[category]" id="record_category_" title="Select a category to filter skills">
```
-   For associations:
    -   `:label_method` with method name (as symbol) of the model to use instead of :to\_label
```
        class User < ApplicationRecord
          belongs_to :skill
          det long_label
            [name, description].compact.join ': '
          end
        end
        class UsersController < ApplicationController
          active_scaffold :user do |conf|
            conf.columns[:skill].form_ui = :select, {label_method: :long_label} # Will call long_label on Skill records for the text of each option.
```
-   For singular associations:
    - the `:optgroup` in options hash will be used to build a grouped options. If the column is an association, and it has `:label_method` in its own controller, in `column.options`, then it will be used instead of `to_label` to display the group name.
```
        conf.columns[:skill_sub_discipline].form_ui = :select, {optgroup: :skill_discipline}
```
  In SkillSubDisciplinesController:
```
        conf.columns[:skill_discipline].options = {label_method: :short_code}
```
    <img src="{{site.baseurl}}/assets/2025/02/299456326-dad96cdb-686e-4d1f-b6e5-5af4df454e77-300x190.png" width="300" height="190" />

    - `:add_new` to add a hidden subform to create a new record, and a link ‘Create New’ to hide the select and display the subform. The subform has a link ‘Add Existing’ to hide the subform and display the select again.
```
        conf.columns[:skill_sub_discipline].form_ui = :select, {add_new: true}
```
    <img src="{{site.baseurl}}/assets/2025/02/298410553-5444bd8b-9ed2-4643-b3f6-14f214658a15-300x28.png" width="300" height="28" />
    <img src="{{site.baseurl}}/assets/2025/02/298410640-56a1e7f2-a7a8-4fbc-a230-04fa3d02bc89-300x43.png" width="300" height="43" />  
    For polymorphic belongs\_to, :add\_new may be an array with model names which will get the ‘Create New’ link when is selected in the foreign\_type column.
    -   `:layout`, when using `add_new`, the layout for the subform can be set with this option, instead of using the layout set in subform.layout of the associated controller.
```
            conf.columns[:skill_sub_discipline].form_ui = :select, {add_new: true, layout: :vertical}
```
        <img src="{{site.baseurl}}/assets/2025/02/298411056-014de5de-6862-4dac-97d3-d11ba462fe16-300x95.png" width="300" height="95" />
    - `:hide_subgroups`, when using `add_new`, the column subgroups of the subform can be hidden. By default, subgroups are visible, with no link to hide, but with this option the subgroups will be hidden and there will be a link to show them.  
        <img src="{{site.baseurl}}/assets/2025/02/298412869-0c7794de-e983-40bf-8f35-fac67426c570-300x97.png" width="300" height="97" />
        <img src="{{site.baseurl}}/assets/2025/02/298413156-d1f01772-24ea-4f6f-8928-dfb6c66db7bf-300x60.png" width="300" height="60" />
- For plural associations:

    - `:draggable_lists` to show two lists, one with available options and the other with selected options; users select them with drag and drop instead of checkboxes.
```
conf.columns[:roles].options = {:draggable_lists => true}
```
      <img src="{{site.baseurl}}/assets/2025/02/298421443-df7dfb6c-a849-4b06-a87f-2aeafd72eba8-300x48.png" width="300" height="48" />

    - `:multiple` can be set in `:html_options`, changing to render as select with multiple attribute. It will add `[]` to the select tag name. In this case, plural associations may have options for `select` rails helper method, and `html_options`, as any column rendering `select` tag.
```
class User < ApplicationRecord
              has_many :skills
            end
            class UsersController < ApplicationController
              active_scaffold :user do |conf|
                conf.columns[:skills].options = :select, {html_options: {html: true}}
```
        <img src="{{site.baseurl}}/assets/2025/02/298686402-9ac3ba32-ed8d-4b26-8a42-b95d06dd8585-300x83.png" width="300" height="83" />

-   For non-association columns:
    - `:options` hash or nested array under options key
      ```
      config.columns[:name].options = {:options => [['some text', 'some value'], ['another text', 'another value']]}
      ``` 
      ```
      <select name="record[name]" id="record_name_">
                          <option value="some value">some text</option>
                          <option value="another value">another text</option>
                          </select>
      ```
    - `:options` array under options key, array elements will be used as values and texts, symbols will be translated to use as texts:
```
config.columns[:name].options = {:options => [:some_value, :another_value]}
```
```
#translation
                    en:
                      activerecord:
                        attributes:
                          model_name:
                            some_value: "Some translated value"
                            another_value: "Another translated value"
```
```
<option value="some_value">Some translated value</option>
                    <option value="another_value">Another translated value</option>
```
    - using `:multiple` in `:html_options`, adds multiple attribute to the select tag, as in plural associations. The column must support saving an array, e.g. using serialize in the model.
```
class User < ApplicationRecord
                      serialize :skills
                    end
                    class UsersController < ApplicationController
                      active_scaffold :user do |conf|
                        conf.columns[:skills].options = :select, {options: ['skill 1', 'skill 2', 'skill 3'], html_options: {html: true}}
```
-   For every column
    - `:refresh_link` adds a refresh link, with text refresh and CSS to show an icon, hiding the text. The refresh link triggers render\_field request, just as changing an option does when update\_columns is enabled. The value can be true, or a Hash with :text option to change the label of the link (although the default CSS hide text and show an icon), and html options for the link.
```
conf.columns[:skill_sub_discipline].form_ui = :select, {refresh_link: {title: 'Click to reload', text: 'Reload'}}
```
```
<select name="record[skill_sub_discipline]" id="record_skill_sub_discipline_"><option value="">- select -</option></select>
                    <a title="Click to reload" href="/controller/render_field?column=skill_sub_discipline">Reload</a>
```

 
:select\_multiple

It works like `:select, {html_options: {multiple: true}}`, to render a select tag with multiple attribute. See explanation at [select](https://github.com/activescaffold/active_scaffold/wiki/Form_ui-types#select)

 
:textarea

It accepts `:cols`, `:rows` and `:size` options, for the `text_area` rails helper method.

 
:time

It renders an input with type time. The options are used as the options argument in `time_field` rails helper method.
```
conf.columns[:due_at].form_ui = :time, {max: 3.hours.since}



<input type="time" name="record[due_at]" id="record_due_at_2" max="11:10:12.317" />
```
:url

It renders input field with type url, in which modern browsers will accept only well-formed URLs (old browsers will treat it as simple text input). Options are passed as options argument to email\_field.

:week

It renders input field with type week, which modern browsers will render as week picker (old browsers will treat it as simple text input). Options are passed as options argument to week\_field.

<img src="{{site.baseurl}}/assets/2025/02/298702347-cbe1ef6b-af26-4d1c-8303-5f262e59f80b-254x300.png" width="254" height="300" />

:telephone

It renders input field with type tel, in which modern browsers will accept only well-formed phone numbers (old browsers will treat it as simple text input). Options are passed as options argument to email\_field.

### Bridge types

:active\_storage\_has\_many

Added by “active\_storage” rails gem, and set by default to ActiveStorage has\_many associations (has\_many\_attached). It renders an input with type file, with multiple attribute, to upload more than one file. When the association has value it shows as the column in the list (if it has more than 3 files then it shows the number of files, otherwise it shows the files), and a link to remove the files, which will show an input file so user can upload other files. It accepts the option `:thumb` with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename.

 
:active\_storage\_has\_many

Added by “active\_storage” rails gem, and set by default to ActiveStorage has\_many associations (has\_many\_attached). It renders an input with type file, with multiple attribute, to upload more than one file. When the association has value it shows as the column in the list (if it has more than 3 files then it shows the number of files, otherwise it shows the files), and a link to remove the files, which will show an input file so user can upload other files. It accepts the option `:thumb` with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename.

:active\_storage\_has\_one

Added by “active\_storage” rails gem, and set by default to ActiveStorage has\_one associations (has\_one\_attached). It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. It accepts the option `:thumb` with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename.

```
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: :thumbnail} # use thumbnail variant
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: {resize: "30x30"}} # display image resized to 30x30
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: false} # display file name
```
<img src="{{site.baseurl}}/assets/2025/02/298722519-6cfe9e18-3006-4066-9feb-58a468823df8-300x41.png" width="300" height="41" />

<img src="{{site.baseurl}}/assets/2025/02/298722882-fce68143-2115-48e3-b0f7-31534a815b9e.png" width="239" height="47" />

The default variant can be set with `ActiveScaffold::Bridges::ActiveStorage.thumbnail_variant` in an initializer, which defaults to `{resize_to_limit: [nil, 30]}`. If no thumb option is provided, default value is used from `thumbnail_variant`.

:ancestry

Added by the gem [ancestry](https://github.com/stefankroes/ancestry). Set by default in parent\_id column of a model using ancestry. It renders a select tag, supporting `:label_method` option as `:select` type.

 
:carrierwave

Added by [carrierwave](https://github.com/carrierwaveuploader/carrierwave) gem, and set by default to uploader fields. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. If the mounter has a version it can be used to display an image instead of the filename, it defaults to use :thumbnail version, but can be changed with `ActiveScaffold::Bridges::Carrierwave::CarrierwaveBridgeHelpers.thumbnail_style` in an initializer.

The UI looks similar to the one for `:active_storage_has_one`.

:chosen

It renders a select using [chosen](https://github.com/tsechingho/chosen-rails) library. It works for the same columns as `:select`, singular and plural associations, or non-association columns. For plural associations accepts options for `select` rails helper method, and html\_options in the :html\_options key. For other columns, it accepts the same options as `:select` form\_ui. You need to add chosen to Gemfile, assets will be added by ActiveScaffold.

- Singular association:

```
    conf.columns[:skill].form_ui = :chosen, {include_blank: 'Select a skill'}
```

<img src="{{site.baseurl}}/assets/2025/02/299009812-663839bc-2a81-46a4-82cc-1dcbebf4de5c.png" width="188" height="127" />

- Plural association:

```
    conf.columns[:roles].form_ui = :chosen
```

<img src="{{site.baseurl}}/assets/2025/02/299010653-266b8e58-cb21-4471-9fc7-e70358a865c6.png" width="220" height="195" />

- Column with options:

```
    conf.columns[:level].form_ui =  :chosen, {options: ['Not Set', 'None', 'Low', 'Medium', 'High', 'Very High']}
```

<img src="{{site.baseurl}}/assets/2025/02/299014029-d434c211-f736-4e14-8a59-abd6e0e153b6.png" width="89" height="213" />

`:optgroup` can be used to group options by another column, as in `:select`:

```
    conf.columns[:skills].form_ui = :chosen, {optgroup: :skill_discipline}
```

:country

It requires [country\_select](https://github.com/countries/country_select) gem. It accepts `:priority` in the options to set :priority\_countries option of `country_select` helper, and `:format`, other options are passed to html\_options of `country_select` helper.

      CountrySelect::FORMATS[:with_alpha2] = lambda do |country|
        "#{country.iso_short_name} (#{country.alpha2})"
      end

 

```
conf.columns[:country].form_ui = :country, {priority: ['US'], format: :with_alpha2, title: 'Select a country'}
```
<img src="{{site.baseurl}}/assets/2025/02/299019553-ac6e05a6-6dcf-4791-8c30-96600b4a64d1-300x92.png" width="300" height="92" />

:date\_picker

This requires the jquery datepicker, datepicker specific options can be passed via the Column\#options hash. When jquery-ui-rails is installed is used for date columns by default. To format input use locale: date.formats.default

 
:datetime\_picker

The same as date\_picker, but with time controls. When jquery-ui-rails is installed is used for datetime columns by default. Format input with locale time.formats.picker

:dragonfly

It requires the [dragonfly](https://github.com/markevans/dragonfly) gem, when the gem is installed, it’s used for dragonfly accessors by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. It accepts the option `:thumb` with a param to pass to `thumb` dragonfly method to be used when displaying the content when the file is an image, if no `:thumb` option is provided, it will use the value defined in `ActiveScaffold::Bridges::Dragonfly::DragonflyBridgeHelpers.thumbnail_style` which defaults to ‘x30&gt;’. If the file is not an image, it will display the filename.

```
conf.columns[:avatar].form_ui = :dragonfly, {thumb: '30x30>'} # use to display a thumbnail
```
The UI looks similar to the one for `:active_storage_has_one`.

 
:file\_column

This requires the [file\_column](https://github.com/tekin/file_column) gem, when the gem is installed, it’s used for columns using file\_column by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file.

The UI looks similar to the one for `:active_storage_has_one`.

:paperclip

This requires the [paperclip](http://github.com/thoughtbot/paperclip) gem, when the gem is installed, it’s used for paperclip columns by default. It renders an input with type file, and when the association has value, it show the file as the column in the list, and a link to remove the file, which will show an input file so user can upload another file. If the paperclip column has a style, it can be used to display an image instead of the filename, it defaults to use :thumbnail style, but can be changed with `ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style` in an initializer.

The UI looks similar to the one for `:active_storage_has_one`.

:record\_select

This requires the [recordselect](https://github.com/scambra/recordselect) gem. It renders a text box to search, calling a record\_select helper:

-   For singular associations, `record_select_field`.
-   For plural associations, `record_multi_select_field`.
-   For non-association columns, `active_scaffold_record_select_autocomplete`

The next options will be passed to the helper:

-   For every column:
    -   `:params` to send to the controller on record select browse and search requests.
-   For associations:
    -   `:controller`, must be a string, although it’s automatically put to the controller for the associated model, it can be overrided with options.
    -   `:field_name` for the text field, which usually has no name, as RecordSelect submits the id with a hidden field.
-   For singular associations:
    -   `:add_new`, to add a hidden subform to create a new record, with a link to hide the record select and display the subform.
    -   `:html_options` hash with key :multiple, to use `record_multi_select_field` helper instead, other options in the hash are ignored.
-   For non-association columns:
    -   `:controller`, must be a string, although it’s automatically put to the current controller, may not be useful and it can be set with options.
    -   `:label` with the current value for the record select, instead of getting using the setting in record\_select config of the controller

Singular association example:

```
conf.columns[:task].form_ui = :record_select
```
<img src="{{site.baseurl}}/assets/2025/02/299335594-284dd11c-fad6-4141-95b3-6121ea4bafcc-300x58.png" width="300" height="58" />

Plural association example:

```
conf.columns[:tasks].form_ui = :record_select, {params: {endDate: ''}}
```
Add `permit_rs_browse_params` to Helpers so `endDate` param is passed to the search requests issued while typing:

```
def permit_rs_browse_params
  [:endDate]
end
```
<img src="{{site.baseurl}}/assets/2025/02/299330855-813fafda-664f-4961-bc99-18a3a830a140-300x67.png" width="300" height="67" />

Autocomplete on column example, will look on the specified controllers, with the record select config, and selecting a record will copy the label into the text field.

```
conf.columns[:task_name].form_ui = :record_select, {controller: 'tasks'}
```
<img src="{{site.baseurl}}/assets/2025/02/299336709-eb3a9942-22e9-4637-9cf0-75e5184cf62f-300x85.png" width="300" height="85" />

There are more explanation about [integrating RecordSelect](https://github.com/activescaffold/active_scaffold/wiki/Record-Select-Integration-%28RecordSelect%29) in the wiki and the [docs for RecordSelect](https://github.com/scambra/recordselect/wiki)

 
:text\_editor

It can be used as :tinymce too. This requires the tinymce-rails gem for rails >= 3.1 or tiny\_mce for rails < 3.1

-   TinyMCE supports multiple configuration sets in the config file. The configuration set to use can be set with `:tinymce_config` option, using `:default` if none is set.

        active_scaffold :product do |conf|
          conf.columns[:description_html].form_ui = :text_editor, {tinymce_config: :alternate}
        end

     

-   The default TinyMCE configuration can be modified via the `:tinymce` option hash. Any [configuration options](http://www.tinymce.com/wiki.php/Configuration) that can be passed via the Javascript `tinyMCE.init({ ... })` may be passed as options

        active_scaffold :product do |conf|
          conf.columns[:description_html].form_ui = :text_editor, {
            tinymce: {
              theme: '<theme_name>',
              editor_css: '/product_editor.css'
            }
          }
        end

     

-   Both options `:tinymce_config` and `:tinymce` can be used, selecting the configuration set, and overriding some options.

 
:usa\_state

It renders select field to choose a USA state. It accepts `:priority` in the options to put at the top some states, and other options accepted by `content_tag` rails helper method.

```
conf.columns[:state].form_ui = :usa_state, {priority: [%w[Alabama AL], %w[Virginia VA]], title: 'Select a state'}
```
<img src="{{site.baseurl}}/assets/2025/02/299023523-5ad3d937-3281-44ff-88c8-a9933dde34e5.png" width="140" height="143" />
