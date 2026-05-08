---
title: "Search_ui types"
category: "UI Types"
---

There are different search_ui types in ActiveScaffold, used in field search form, some may be useful for some column types only. The search ui types may use options from column's options hash (`conf.columns[:xxx].options = {...}`), or an options hash set next to the type (`conf.columns[:xxx].search_ui = :yyy, {...}`). If no search_ui is set, it will use the value from form_ui, using the options set with form_ui assignment, or column's options hash if no options were set with the form_ui.

The same form_ui types are available for search_ui too, only explained here if there are some differences with the usage in form_ui.

## Basic types

### :boolean

It renders a select box with `true` and `false` options. It will have `- select-` option to avoid adding search on the column. If the column can be null, will have `Null` option (or the label set in options[:include_blank]).

![image](/assets/screenshots/search-ui-boolean.png)

![image](/assets/screenshots/search-ui-boolean-nullable.png)

{% highlight ruby -%}
conf.columns[:approved].form_ui = :boolean, {include_blank: 'Not Set'}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-boolean-custom-blank.png)

### :checkbox

It renders the same as `:boolean` in the search form, as a checkbox doesn't allow to choose if searching by that column or not.

### :checkboxes

It renders a collection of checkboxes, it's the same as `:multi_select`, see explanation at [multi_select](/doc/search_ui-types/#multi_select). It supports @:draggable_lists@ option, as in @:multi_select@ UI. 

### :date

Date columns will use this search_ui by default, if form_ui and search_ui is nil. If the form_ui is changed, and want to use the default search_ui for date columns, set `search_ui` to `:date`.

It renders a select box with comparator operators, returned by `active_scaffold_search_datetime_comparator_options` helper: `past`, `future`, `range`, `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null, the behaviour can be changed using `null_comparators: false` in UI options or column options, to never include these operators.

![image](/assets/screenshots/search-ui-date-comparators.png)

The helper `active_scaffold_search_datetime_comparator_options` can be overrided to change the operators available:

{% highlight ruby -%}
  def active_scaffold_search_datetime_comparator_options(column, ui_options: column.options)
    if column.name == :birthday
      valid = ActiveScaffold::Finder::NUMERIC_COMPARATORS
      super.select { |_, op| op.in? valid }
    else
      super
    end
  end
{%- endhighlight %}

When the operator `between` is selected, 2 date fields are displayed to find values between 2 dates. When `null` or `not null` operators are selected, no date field is displayed.

`Past` and `Future` will display a number field and a date unit select box with options `days`, `weeks`, `months`, `years`:

![image](/assets/screenshots/search-ui-date-trend.png)

The available units can be changed overriding `active_scaffold_search_datetime_trend_units` helper:

{% highlight ruby -%}
def active_scaffold_search_datetime_trend_units(column)
  if column.column_type == :date
    ['DAYS', 'WEEKS', 'MONTHS'].collect { |unit| [as_(unit.downcase.to_sym), unit] }
  else
    super
  end
end
{%- endhighlight %}

`Range` will display a select box with different options: `today`, `yesterday`, `tomorrow`, `this week`, `last week`, `next week`, `this month`, `last month`, `next month`, `this year`, `last year`, `next year`.

![image](/assets/screenshots/search-ui-date-range.png)

### :datetime

Datetime columns will use this search_ui by default, if form_ui and search_ui is nil. If the form_ui is changed, and want to use the default search_ui for datetime columns, set `search_ui` to `:datetime`. It's aliased as `:timestamp` so it's used by default by timestamp columns too.

It renders a select box with comparator operators, returned by `active_scaffold_search_datetime_comparator_options` helper: `past`, `future`, `range`, `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null, the behaviour can be changed using `null_comparators: false` in UI options or column options, to never include these operators.

![image](/assets/screenshots/search-ui-date-comparators.png)

The helper `active_scaffold_search_datetime_comparator_options` can be overrided to change the operators available:

{% highlight ruby -%}
  def active_scaffold_search_datetime_comparator_options(column, ui_options: column.options)
    if column.name == :birthday
      valid = ActiveScaffold::Finder::NUMERIC_COMPARATORS
      super.select { |_, op| op.in? valid }
    else
      super
    end
  end
{%- endhighlight %}

When the operator `between` is selected, 2 datetime-local fields are displayed to find values between 2 dates. When `null` or `not null` operators are selected, no datetime-local field is displayed.

`Past` and `Future` will display a number field and a date or time unit select box with options `seconds`, `minutes`, `hours`, `days`, `weeks`, `months`, `years`:

![image](/assets/screenshots/search-ui-date-trend.png)

The available units can be changed overriding `active_scaffold_search_datetime_trend_units` helper:

{% highlight ruby -%}
def active_scaffold_search_datetime_trend_units(column)
  if column.column_type == :date
    super
  else
    super.reject { |_, op| op == 'SECONDS' }
  end
end
{%- endhighlight %}

`Range` will display a select box with different options: `today`, `yesterday`, `tomorrow`, `this week`, `last week`, `next week`, `this month`, `last month`, `next month`, `this year`, `last year`, `next year`.

![image](/assets/screenshots/search-ui-date-range.png)


### :decimal

It renders a select box with comparator operators, returned by `active_scaffold_search_range_comparator_options` helper: `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null, the behaviour can be changed using `null_comparators: false` in UI options or column options, to never include these operators.

![image](/assets/screenshots/search-ui-numeric-comparators.png)

The helper `active_scaffold_search_range_comparator_options` can be overrided to change the operators available, as explained for `:string` search ui.

When the operator `between` is selected, 2 fields are displayed to find values between 2 numbers. When `null` or `not null` operators are selected, no number field is displayed. The number fields will have step attribute set to `any`, to accept decimal, but it can be changed in the options hash when setting search_ui or `column.options`, and `min` and `max` options are supported too.

It's aliased as `:float` too.

### :draggable

It's the same as `:multi_select, {draggable_lists: true}`, see explanation at [multi_select](/doc/search_ui-types/#multi_select).

### :integer

It renders a select box with comparator operators, returned by `active_scaffold_search_range_comparator_options` helper: `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null, the behaviour can be changed using `null_comparators: false` in UI options or column options, to never include these operators.

![image](/assets/screenshots/search-ui-numeric-comparators.png)

The helper `active_scaffold_search_range_comparator_options` can be overrided to change the operators available, as explained for `:string` search ui.

When the operator `between` is selected, 2 fields are displayed to find values between 2 numbers. When `null` or `not null` operators are selected, no number field is displayed. The number fields will have step attribute set to `1`, to accept only integers, but it can be changed in the options hash when setting search_ui or `column.options`, and `min` and `max` options are supported too.

### :multi_select

It renders a list of checkboxes to allow searching for multiple values. It can be used with any column, even with singular associations, to allow searching for multiple values, finding records which have any of the selected values.

{% highlight ruby -%}
conf.columns[:contract_type].search_ui =:multi_select, {options: ['Not Set','CPAF','COST', 'TM' ,'FFP', 'MS']}
{%- endhighlight %}
![image](/assets/screenshots/search-ui-multi-select.png)

Valid options:
* :draggable_lists to show two lists, one with available options and the other with selected options; users select them with drag and drop instead of checkboxes.
{% highlight ruby -%}
conf.columns[:contract_type].search_ui =:multi_select, {draggable_lists: true, options: ['Not Set','CPAF','COST', 'TM' ,'FFP', 'MS']}
{%- endhighlight %}
![image](/assets/screenshots/search-ui-multi-select-draggable.png)


### :null

It renders a select box with `Null` and `Not Null` options to search if the column is null or not.

{% highlight ruby -%}
conf.columns[:birthday].search_ui = :null
{%- endhighlight %}

![image](/assets/screenshots/search-ui-null.png)

### :select

It renders a select tag, to pick a value to look for records with that value. Plural associations won't use checkboxes as form_ui does. It will look for available options in the same way as form_ui does. Search_sql must be set as `#{table_name}.#{primary_key}` for associations, which is the default value.

If the column, or foreign key for `belongs_to` associations, can be null, then a select box with comparator operators `=`, `Null` and `Not Null` will be displayed before the select tag with values:

![image](/assets/screenshots/search-ui-select-null-comparators.png)

Using `null_comparators: false` in UI options or column options, will skip the select box with comparator operators.

Valid options:
* For all columns:
  * options for the select rails method.
{% highlight ruby -%}
  conf.columns[:skill].form_ui = :select, {include_blank: 'Pick one'}
{%- endhighlight %}
{% highlight html -%}
  <select name="search[skill]" class="skill-input" id="record_skill">
  <option value="">Pick one</option>
  </select>
{%- endhighlight %}
  * html options hash under html_options key
{% highlight ruby -%}
  config.columns[:category].options = {html_options: {title: 'Select a category to look for'}}
{%- endhighlight %}
{% highlight html -%}
  <select name="search[category]" class="category-input" id="record_category" title="Select a category to look for">
{%- endhighlight %}
  * :multiple can be set in :html_options, changing to render as select with multiple attribute. It will add `[]` to the select tag name.
{% highlight ruby -%}
      conf.columns[:skill].options = :select, {html_options: {multiple: true}}
{%- endhighlight %}
  ![image](/assets/screenshots/search-ui-select-multiple.png)
* For associations:
  * :label_method with method name (as symbol) of the model to use instead of :to_label
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
  * the :optgroup in options hash will be used to build a grouped options. If the column has :label_method in its own controller, in column.options, then it will be used instead of to_label to display the group name.
{% highlight ruby -%}
  conf.columns[:skill_sub_discipline].form_ui = :select, {optgroup: :skill_discipline}
{%- endhighlight %}
  In SkillSubDisciplinesController:
{% highlight ruby -%}
  conf.columns[:skill_discipline].options = {label_method: :short_code}
{%- endhighlight %}
  ![image](/assets/screenshots/search-ui-select-optgroup.png)

### :select_multiple

It's the same as `:select, {html_options: {multiple: true}}`, rendering as select with multiple attribute. It can be used with any column, even with singular associations, to allow searching for multiple values, finding records which have any of the selected values.

### :string

String columns will use this search_ui by default, if form_ui and search_ui is nil. If the form_ui is changed, and want to use the default search_ui for string columns, set `search_ui` to `:string`.

It renders a select box with comparator operators, returned by `active_scaffold_search_range_comparator_options` helper: `contains`, `begins with`, `ends with`, `doesn't contain`, `doesn't begin with`, `doesn't end with`, `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null, the behaviour can be changed using `null_comparators: false` in UI options or column options, to never include these operators.

![image](/assets/screenshots/search-ui-string-comparators.png)

The helper `active_scaffold_search_range_comparator_options` can be overrided to change the operators available:

{% highlight ruby -%}
  def active_scaffold_search_range_comparator_options(column, ui_options: column.options)
    if active_scaffold_search_range_string?(column)
      valid = ActiveScaffold::Finder::STRING_COMPARATORS.values + ['=', '!=']
      super.select { |_, op| op.in? valid }
    else
      super
    end
  end
{%- endhighlight %}

When the operator `between` is selected, 2 fields are displayed to find values between 2 strings. When `null` or `not null` operators are selected, no text field is displayed.

### :text

For simple text field. It’s useful when it has a form_ui but you want a simple text field for search view, without the operator options of `:string`.

### :time

Time columns will use this search_ui by default, if form_ui and search_ui is nil. If the form_ui is changed, and want to use the default search_ui for time columns, set `search_ui` to `:time`.

It renders a select box with comparator operators, returned by `active_scaffold_search_datetime_comparator_options` helper: `past`, `future`, `range`, `=`, `>=`, `<=`, `>`, `<`, `!=`, `between`. It will include `Null` and `Not Null` if the column can be null.

![image](/assets/screenshots/search-ui-date-comparators.png)

The helper `active_scaffold_search_datetime_comparator_options` can be overrided to change the operators available, as explained for `:datetime` search ui.

When the operator `between` is selected, 2 time fields are displayed to find values between 2 dates. When `null` or `not null` operators are selected, no time field is displayed.

`Past` and `Future` will display a number field and a date or time unit select box with options `seconds`, `minutes`, `hours`, `days`, `weeks`, `months`, `years`:

![image](/assets/screenshots/search-ui-date-trend.png)

The available units can be changed overriding `active_scaffold_search_datetime_trend_units` helper:

{% highlight ruby -%}
def active_scaffold_search_datetime_trend_units(column)
  if column.column_type == :date
    super
  else
    super.reject { |_, op| op == 'SECONDS' }
  end
end
{%- endhighlight %}

`Range` will display a select box with different options: `today`, `yesterday`, `tomorrow`, `this week`, `last week`, `next week`, `this month`, `last month`, `next month`, `this year`, `last year`, `next year`.

![image](/assets/screenshots/search-ui-date-range.png)


## Bridge types

### :calendar_date_select

This requires the [calendar date select](https://code.google.com/p/calendardateselect/) plugin. Plugin specifics can be passed via the Column#options hash. When the plugin is installed is used for date and datetime columns by default. It works as `:date` or `:datetime` search_ui, but using calendar date select for date and time pickers.

### :chosen

It renders a select using [chosen](https://github.com/tsechingho/chosen-rails) library. It works for the same columns as `:select`, singular and plural associations, or non-association columns. For plural associations accepts options for `select` rails helper method, and html_options in the `:html_options` key. For other columns, it accepts the same options as `:select` form_ui. You need to add chosen to Gemfile, assets will be added by ActiveScaffold. 

Association (singular or plural):
{% highlight ruby -%}
conf.columns[:skill].search_ui = :chosen, {include_blank: 'Select a skill'}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-chosen.png)
 
With multiple choices:
{% highlight ruby -%}
conf.columns[:roles].search_ui = :chosen, {html_options: {multiple: true}}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-chosen-multiple.png)

Column with options:
{% highlight ruby -%}
conf.columns[:level].search_ui =  :chosen, {options: ['Not Set', 'None', 'Low', 'Medium', 'High', 'Very High']}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-chosen-with-options.png)

`:optgroup` can be used to group options by another column, as in `:select`:
{% highlight ruby -%}
conf.columns[:skills].search_ui = :chosen, {optgroup: :skill_discipline}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-chosen-optgroup.png)


### :country

It requires [country_select](https://github.com/countries/country_select) gem. It accepts `:priority` in the options to set `:priority_countries` option of `country_select` helper, and `:format`, other options are passed to html_options of `country_select` helper.

{% highlight ruby -%}
conf.columns[:country].search_ui = :country, {priority: ['US']}
{%- endhighlight %}
![image](/assets/screenshots/search-ui-country.png)

Adding new format, so it can be used with ActiveScaffold, form_ui or search_ui. Put it in initializer:
{% highlight ruby -%}
    CountrySelect::FORMATS[:with_alpha2] = lambda do |country|
      "#{country.iso_short_name} (#{country.alpha2})"
    end
{%- endhighlight %}
{% highlight ruby -%}
conf.columns[:country].search_ui = :country, {priority: ['US'], format: :with_alpha2, title: 'Select a country'}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-country-with-format.png)

### :date_picker

This requires the jquery-ui datepicker, datepicker specific options can be passed via the Column#options hash. When jquery-ui-rails is installed is used for date columns by default. To format input use locale: date.formats.default. It works as `:date` search_ui, but using jquery-ui datepicker for date picker.

### :datetime_picker

The same as date_picker, but with time controls. When jquery-ui-rails is installed is used for datetime columns by default. Format input with locale time.formats.picker. It works as `:datetime` search_ui, but using jquery-ui datepicker for date and time pickers.

### :multi_chosen

It's the same as `:chosen, {html_options: {multiple: true}}`, see explanation at [chosen](/doc/search_ui-types/#chosen).

### :record_select

This requires the [recordselect](https://github.com/scambra/recordselect) gem. It renders a text box to search, calling `record_select_field` helper. Only works for association columns. When `multiple: true` is set in options, `record_multi_select_field` helper is used instead.

The next options will be passed to the record_select helper:
* :params to send to the controller on record select browse and search requests.
* :controller, must be a string, although it's automatically put to the controller for the associated model, it can be overrided with options.
* :field_name for the text field, which usually has no name, as RecordSelect submits the id with a hidden field.

Association example:

{% highlight ruby -%}
conf.columns[:task].search_ui = :record_select
{%- endhighlight %}

![image](/assets/screenshots/search-ui-record-select.png)


Example with params:

{% highlight ruby -%}
conf.columns[:tasks].search_ui = :record_select, {params: {endDate: ''}}
{%- endhighlight %}

Add `permit_rs_browse_params` to Helpers so `endDate` param is passed to the search requests issued while typing:

{% highlight ruby -%}
  def permit_rs_browse_params
    [:endDate]
  end
{%- endhighlight %}

Example with multiple option:

{% highlight ruby -%}
conf.columns[:tasks].search_ui = :record_select, {multiple: true}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-record-select-multiple.png)

### :text_editor

It just renders a text field to search, so fields using text_editor form_ui will default to simple text field in the search form.

### :usa_state

It renders select field to choose a USA state. It accepts `:priority` in the options to put at the top some states, and other options accepted by `content_tag` rails helper method.

{% highlight ruby -%}
conf.columns[:state].search_ui = :usa_state, {priority: [%w[Alabama AL], %w[Virginia VA]], title: 'Select a state'}
{%- endhighlight %}

![image](/assets/screenshots/search-ui-usa-state.png)
