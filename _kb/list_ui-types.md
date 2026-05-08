---
title: "List_ui types"
category: "UI Types"
---

There are different list_ui types in ActiveScaffold, some may be useful for some column types only. The list ui types may use options from column’s options hash (conf.columns[:xxx].options = {...}), or an options hash set next to the type (conf.columns[:xxx].list_ui = :yyy, {...}).

## Default helper methods

When no list_ui is set, and no form_ui, or the form_ui is not available as list_ui (@active_scaffold_column_<list_ui>@ helper), then `format_column_value` helper is used to format the value.

### format_column_value

It's the default helper used to render columns in the list, when no list UI or [column override](/doc/column-overrides-list/) is defined for the column.

Then it may use different methods to format the value:

* If the list is using grouped search on this column, and using a group function, it will call `format_grouped_search_column` to format the value.
* If the value is a number, it will call `format_number_value` to format it.
* Otherwise will use `format_value`.

If the column is an association, it will use `format_association_value`.

### format_association_value

It will use `:to_label` method to get the associated record's label, although it can be changed with `:label_method` in column options hash.

If it's a singular association, and it's polymorphic, it will display as `<model>: <label>`, using `model_name.human` to translate the model's name.

If it's a collection association, the format will depend on the column settings `associated_limit` and `associated_number`:

* If `associated_limit` is `nil`, it will display the labels for all associated records, better to use `includes` to preload the association (as set by default) to reduce the number of SQL queries.
* If `associated_limit` is 0, then will display the count of associated records if `associated_number` is enabled. If the column is preloaded, or has a counter cache, it will get the count from the association, otherwise a group query is used to get the counts for all listed records with one SQL query (see [Preload Column Counts](/doc/preload-column-counts/)). If the associated records are not needed for permission methods or other helpers, it's better to avoid preloading them by setting `includes = nil` so a counter cache or count query is used, which is faster.
* If `associated_limit` has other value (defaults to 3), it will list the label for associated records upto the limit, will add `… (<size>)` if the association has more associated records. The size won't be added unless `associated_number` is enabled. In this case, it's better to preload the associated records, unless the association may be too big.
  * If the column has 3 or less records: `Record 1, Record 2, Record 3`
  * If the column has more than 3 records, associated_number enabled: `Record 1, Record 2, Record 3, … (4)`
  * If the column has more than 3 records, associated_number disabled: `Record 1, Record 2, Record 3, …`

The recommended settings to get the next goals are:

* Displaying all associated records: `associated_limit = nil`, default includes (`includes = [:association]`), associated_number doesn't matter. Add other associations needed for the label method to the includes. Don't use it for big associations.
* Displaying few records if association is not too big: set associated_limit to the wanted number (or leave default value of 3), leave includes with default value or add other associations needed for the label method to the includes, disable associated_number if don't want to display the size.
* Displaying few records on big associations: set associated_limit to the wanted number (or leave default value of 3), set `includes = nil` to avoid loading all associated records, will use a query on each row to get few records to display. Disable associated_number if want to avoid another query to count the records, enable it will use a group query to count associated records for the rendered records.
* Displaying the size, useful for big associations: `associated_limit = 0`, `includes = nil`, will use counter cache or one group query to count associated records for the rendered records.

When associated records' labels are displayed, they are join with the text in `config.list.association_join_text`, but can be changed on each column with `association_join_text` setting in the column.


### format_grouped_search_column

If the group search function is `year_month` or `month`, it will use I18n.localize to format the value, if the function is `year_quarter` or `quarter`, then it will use I18n.translate to format the value. In both cases, it will use the group search function as format name under `date.formats` in the locale file, although it can be changed with `:group_format` option in the column's options hash. See [Grouped Searches](/doc/grouped-searches/) for the explanation on using them.

### format_number_value

The `:format` option in column's options hash can be set to use different rails helpers to format numbers. `:i18n_options` option will be used as options argument when calling the helper:

* `:size` will use `number_to_human_size` to format as data size.
* `:percentage` will use `number_to_percentage`.
* `:currency` will use `number_to_currency`, defaults to currency in locale file.
* `:i18n_number` will use `number_with_delimiter` if value is Integer or `number_with_precision` for Float or Decimal values.

Format option is set to `:i18n_number` by default for columns with type float, decimal or integer (or Numeric type for mongoid models).

### format_value

* When the column is empty, it uses `empty_field_text` helper method, which will return `config.list.empty_field_text`.
* If the value is a Time or Date, will use I18n.localize method with format from `:format` option in column's options hash, default to `:default`.
* If the value is `true` or `false`, will use translation.
* Otherwise will display the value as it's

## Basic types

### :boolean

It displays True or False (translated), when the value is a Boolean. If the value is nil, and `include_blank` is set in the ui options (or column options if ui options are not defined), it will display that value, otherwise will display what is set for empty field in `config.list.empty_field_text`. When the value is not nil, it actually uses `format_column_value` helper to format the value.

{% highlight ruby -%}
conf.columns[:approved].list_ui = :boolean, {include_blank: 'Not Set'}
{%- endhighlight %}

It's the default list_ui (because inherits from form_ui) for boolean type columns which can be null since v2.4+, previously default for all boolean type columns.

### :checkbox

It displays a disabled checkbox. If inplace edit is enabled, the checkbox won't be disabled, allowing to change the value in the list.

{% highlight ruby -%}
conf.columns[:approved].list_ui = :checkbox
conf.columns[:approved].inplace_edit = true
{%- endhighlight %}

It's the default list_ui (because inherits from form_ui) for boolean type columns which can't be null since v2.4+.

### :checkboxes

For association columns just calls `format_column_value`. If the column is not an association, then it will render an unordered list of values, and for each value it will look for the saved value in the options set in form_ui options (or Column#options hash), and will use the text for the saved value, as it's displayed in the form.

### :draggable

For association columns just calls `format_column_value`. If the column is not an association, then it will render an unordered list of values, and for each value it will look for the saved value in the options set in form_ui options (or Column#options hash), and will use the text for the saved value, as it's displayed in the form.

### :fulltext

It's useful to change the default list_ui of columns with text type, to display the whole content.

### :month

Formats a date using I18n.l with `format: :year_month`, which uses the translation in `date.formats.year_month`, defined in ActiveScaffold locale files. It's the same as leaving list_ui empty, and set `format: :year_month` in Column#options hash, but it's useful to have it so using `form_ui = :month` doesn't require to set `:format` in Column#options hash.

### :percentage

It displays the value as a [jquery-ui slider](https://jqueryui.com/slider/), with the as_slider helper, which displays a `<span>` tag with class `as-slider` and `data-slider-` attributes with the slider options.

These options can be used, under `:slider` key:
* min_method: with the name of a method in the model to get the minimum value, then it's passed to slider in data-slider-min attribute.
* max_method: with the name of a method in the model to get the maximum value, then it's passed to slider in data-slider-max attribute.
* disabled: to render slider as readonly.
* any option accepted by jQueryUI slider.

{% highlight ruby -%}
conf.columns[:score].list_ui = :slider, {slider: {disabled: true, min: 0, max: 10}}
{%- endhighlight %}

### :radio

For association columns just calls `format_column_value`. If the column is not an association, then it will look for the saved value in the options set in form_ui options (or Column#options hash), and will use the text for the saved value, as it's displayed in the form.

### :select

For association columns just calls `format_column_value`. If the column is not an association, then it will look for the saved value in the options set in form_ui options (or Column#options hash), and will use the text for the saved value, as it's displayed in the form.

### :select_multiple

For association columns just calls `format_column_value`. If the column is not an association, then it will render an unordered list of values, and for each value it will look for the saved value in the options set in form_ui options (or Column#options hash), and will use the text for the saved value, as it's displayed in the form.

### :telephone

It renders as a link with `tel:` URL, the text of the link is formatted as a number with `number_to_phone` rails helper, unless `:format` option is set to false.

{% highlight ruby -%}
conf.columns[:phone].list_ui = :telephone, {format: false} # rails doesn't know how to format spanish phone numbers, only US phone numbers
{%- endhighlight %}

### :text

It's used automatically in columns with text type, it displays text truncated to 50 chars in length, but it can be changed with `:truncate` in the ui options hash (or Column#options hash).

### :week

Formats a date using I18n.l with `format: :week`, which uses the translation in `date.formats.week`, defined in ActiveScaffold locale files. It's the same as leaving list_ui empty, and set `format: :week` in Column#options hash, but it's useful to have it so using `form_ui = :week` doesn't require to set `:format` in Column#options hash.

## Bridge types

### :active_storage_has_many

Added by "active_storage" rails gem, and set by default to ActiveStorage has_many associations (`has_many_attached`).

If has more than 3 attached files, it just list the number of attached files with the column name (e.g. "3 photos" for `has_many_attached :photos`).

If has some file attached, and less than or equal to 3, it displays the image if a variant is defined and attachment can be transformed by ImageMagick (its content type is in `ActiveStorage.variable_content_types`). The variant is defined by `:thumb` option in the UI options (or Column#options hash), with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename. If `:thumb` is not set, the default variant is used. The default variant can be set with `ActiveScaffold::Bridges::ActiveStorage.thumbnail_variant` in an initializer, which defaults to `{resize_to_limit: [nil, 30]}`. Each image or filename will be a link to download the file.


### :active_storage_has_one

Added by "active_storage" rails gem, and set by default to ActiveStorage has_one associations (`has_one_attached`). If it has an attachment, it displays the image if a variant is defined and attachment can be transformed by ImageMagick (its content type is in `ActiveStorage.variable_content_types`). The variant is defined by `:thumb` option in the UI options (or Column#options hash), with the variant name or ActiveStorage settings to be used when displaying the content, or false to display the filename. If `:thumb` is not set, the default variant is used. The default variant can be set with `ActiveScaffold::Bridges::ActiveStorage.thumbnail_variant` in an initializer, which defaults to `{resize_to_limit: [nil, 30]}`. The image or filename will be a link to download the file.

It's usually set as form_ui, to have form_ui to attach a file, and list_ui will use the same UI and options.

{% highlight ruby -%}
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: :thumbnail} # use thumbnail variant
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: {resize: "30x30"}} # display image resized to 30x30
conf.columns[:avatar].form_ui = :active_storage_has_one, {thumb: false} # display file name
{%- endhighlight %}

### :carrierwave

Added by [carrierwave](https://github.com/carrierwaveuploader/carrierwave) gem, and set by default to uploader fields. If it has an attachment, it displays the image using default thumbnail style, if the mounter has a version with the same name. The default is `:thumbnail` version, but can be changed with `ActiveScaffold::Bridges::Carrierwave::CarrierwaveBridgeHelpers.thumbnail_style` in an initializer. If the thumbnail style version is not defined, it will display the filename. The image or filename will be a link to download the file.

### :country

It requires [country_select](https://github.com/countries/country_select) gem. The column saves the country code, which is used to find the country in `ISO3166::Country` and display the translation from current locale, or `country.name`.

### :download_link

This requires the [file_column](https://github.com/tekin/file_column) gem. It renders a link with `Download` text to download the file.

### :download_link_with_filename

This requires the [file_column](https://github.com/tekin/file_column) gem, when the gem is installed, it's used for columns using file_column by default if they don't have `thumb` image version. It renders a link with the filename to download the file.

### :dragonfly

It requires the [dragonfly](https://github.com/markevans/dragonfly) gem. When the gem is installed, it's used for dragonfly accessors by default. If it has an attachment, and it's an image, it displays the image by calling `thumb` method with the thumbnail style, set in `:thumb` UI option (or Column#options hash), or default thumbnail style if not set. The default is `'x30>'`, but can be changed with `ActiveScaffold::Bridges::Dragonfly::DragonflyBridgeHelpers.thumbnail_style` in an initializer. If the file is not an image, it will display the filename. The image or filename will be a link to download the file, it will use `remote_url` method to get the url, or `url` method if `:private_store` is set in UI options (or Column#options hash).

It's usually set as form_ui, to have form_ui to attach a file, and list_ui will use the same UI and options.

{% highlight ruby -%}
conf.columns[:avatar].form_ui = :dragonfly, {thumb: '30x30>'} # use to display a thumbnail
{%- endhighlight %}

### :paperclip

This requires the [paperclip](https://github.com/thoughtbot/paperclip) gem, when the gem is installed, it's used for paperclip columns by default. If it has an attachment, it displays the image using default thumbnail style, if the paperclip column has a style with the same name. The default is `:thumbnail` style, but can be changed with `ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style` in an initializer. If the thumbnail style is not defined, it will display the filename. The image or filename will be a link to download the file.

### :thumbnail

This requires the [file_column](https://github.com/tekin/file_column) gem, when the gem is installed, it's used for columns using file_column by default if they don't have `thumb` image version. It renders a link with the filename to download the file.