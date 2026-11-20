# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold_config_mock'
require File.expand_path('../../lib/active_scaffold/bridges/date_picker/ext', __dir__)

class DatePickerTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::FormColumnHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::SearchColumnHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::DatepickerColumnHelpers

  def setup
    @controller.class.class_eval do
      include ActiveScaffoldConfigMock
      include ActiveScaffold::Finder
    end
  end

  def test_set_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    assert_nil config.columns[:name].form_ui, 'form_ui for name'
    assert_equal :date_picker, config.columns[:date].form_ui, 'form_ui for date'
    assert_equal :datetime_picker, config.columns[:datetime].form_ui, 'form_ui for datetime'
  end

  def test_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    @record = Company.new
    opts = {object: @record}
    assert active_scaffold_input_date_picker(config.columns[:date], opts.merge(id: 'record_date', name: 'record[date]'))
    assert active_scaffold_input_date_picker(config.columns[:datetime], opts.merge(id: 'record_date', name: 'record[datetime]'))
  end

  def test_form_ui_with_named_callback
    config = ActiveScaffold::Config::Core.new(:company)
    config.columns[:date].options[:data] = {beforeshowday: 'availableDate'}
    @record = Company.new

    html = active_scaffold_input_date_picker(
      config.columns[:date],
      {object: @record, id: 'record_date', name: 'record[date]'}
    )

    assert_includes html, 'data-beforeshowday="availableDate"'
  end

  def test_bridge_exposes_localization_for_dynamic_asset_loading
    bridge = ActiveScaffold::Bridges::DatePicker

    assert_equal 'jquery-ui-timepicker-addon', bridge.stylesheets
    assert_nothing_raised { bridge.install }

    data = bridge.localization_data
    assert_equal I18n.locale.to_s, data[:locale]
    assert data[:datepickerRegional].key?(I18n.locale.to_s)
    assert data[:timepickerRegional].key?(I18n.locale.to_s)

    javascript = bridge.localization
    assert_includes javascript, '$.datepicker.setDefaults'
    assert_includes javascript, '$.timepicker.setDefaults'
    assert_includes javascript, "regional['#{I18n.locale}']"
  end

  def test_format_conversion_supports_date_time_ampm_and_unsupported_tokens
    helper = ActiveScaffold::Bridges::DatePicker::Helper

    assert_equal 'yy-mm-dd', helper.to_datepicker_format('%Y-%m-%d')
    assert_equal ['yy-mm-dd', 'HH:mm:ss'], helper.split_datetime_format('yy-mm-dd HH:mm:ss')
    assert_equal ['yy-mm-dd', nil], helper.split_datetime_format('yy-mm-dd')
    assert_equal [nil, nil], helper.split_datetime_format(nil)
    assert_equal({dateFormat: 'yy-mm-dd', timeFormat: 'hh:mm tt', ampm: true},
                 helper.format_to_datetime_picker('%Y-%m-%d %I:%M %p'))

    Rails.logger.expects(:warn).with(includes("can't be converted"))
    assert_equal '', helper.to_datepicker_format('%c')
  end

  def test_localized_options_normalize_configuration_values
    helper = ActiveScaffold::Bridges::DatePicker::Helper

    assert_equal({enabled: true, disabled: false, firstDay: 1, label: 'Today'},
                 helper.normalize_translated_values(
                   enabled: 'true', disabled: 'false', firstDay: '1', label: 'Today'
                 ))

    date_options = helper.date_options(I18n.locale)
    assert_equal true, date_options[:changeYear]
    assert_equal true, date_options[:changeMonth]
    assert date_options[:monthNames].many?
    assert date_options[:dateFormat].present?

    datetime_options = helper.datetime_options(I18n.locale)
    assert_equal false, datetime_options[:ampm]
    assert datetime_options[:dateFormat].present?
    assert datetime_options[:timeFormat].present?
  end

  def test_default_date_picker_ui_can_be_disabled
    previous_default = ActiveScaffold::Bridges::DatePicker.default_ui
    ActiveScaffold::Bridges::DatePicker.default_ui = false

    config = ActiveScaffold::Config::Core.new(:company)

    assert_nil config.columns[:date].form_ui
    assert_nil config.columns[:datetime].form_ui
  ensure
    ActiveScaffold::Bridges::DatePicker.default_ui = previous_default
  end

  def test_finder_uses_picker_types_and_configured_datetime_formats
    config = ActiveScaffold::Config::Core.new(:company)
    date_column = config.columns[:date]
    datetime_column = config.columns[:datetime]
    finder = controller.class

    assert_equal :to_date, finder.send(:datetime_conversion_for_condition, date_column)
    assert finder.send(:datetime_column_date?, date_column)
    assert_not finder.send(:datetime_column_date?, datetime_column)

    plain_column = config.columns[:name]
    assert_equal :to_time, finder.send(:datetime_conversion_for_condition, plain_column)
    assert_not finder.send(:datetime_column_date?, plain_column)

    formatted_date = finder.send(:format_for_date, date_column, '2026-11-20', :date_picker, {})
    assert_equal ['2026-11-20', I18n.t('date.formats.default')], formatted_date

    I18n.backend.store_translations(:en, time: {formats: {bridge_test: '%Y-%m-%d %H:%M:%S'}})
    format, offset = finder.send(
      :format_for_datetime, datetime_column, '2026-11-20 12:30', :datetime_picker, {format: :bridge_test}
    )
    assert_equal '%Y-%m-%d %H:%M', format
    assert_nil offset

    format, offset = finder.send(
      :format_for_datetime, datetime_column, '12:30 +02:00', :datetime_picker, {format: :bridge_test}
    )
    assert_equal '%H:%M %z', format
    assert_equal 7200, offset
  end

  def test_attribute_params_uses_date_conversion_only_for_date_picker_fields
    config = ActiveScaffold::Config::Core.new(:company)
    attribute_params = Object.new.extend(ActiveScaffold::AttributeParams)

    assert_equal :to_date,
                 attribute_params.send(:datetime_conversion_for_value, config.columns[:date])
    assert_equal :to_time,
                 attribute_params.send(:datetime_conversion_for_value, config.columns[:datetime])
  end

  def test_search_picker_formats_hash_values_and_honors_hidden_fields
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:date]
    options = {id: 'search_date', name: 'search[date]', show: false}
    current_search = {'from' => {year: '2026', month: '11', day: '20'}}

    html = active_scaffold_search_date_picker_field(column, options, current_search, 'from')

    assert_includes html, 'id="search_date_from"'
    assert_includes html, 'name="search[date][from]"'
    assert_includes html, 'class="text-input date_picker"'
    assert_includes html, 'style="display: none"'
    assert_includes html, 'value="2026-11-20"'

    direct_html = active_scaffold_search_date_picker_field(
      column, {id: 'search_date', name: 'search[date]'}, {'to' => Date.new(2026, 11, 21)}, 'to'
    )
    assert_includes direct_html, 'value="2026-11-21"'
  end

  def test_form_picker_applies_named_date_and_datetime_formats
    config = ActiveScaffold::Config::Core.new(:company)
    record = Company.new
    record.stubs(:date).returns(Date.new(2026, 11, 20))
    record.stubs(:datetime).returns(Time.zone.local(2026, 11, 20, 12, 30))
    I18n.backend.store_translations(
      :en,
      date: {formats: {bridge_test: '%d/%m/%Y'}},
      time: {formats: {bridge_test: '%d/%m/%Y %H:%M'}}
    )

    date_html = active_scaffold_input_date_picker(
      config.columns[:date],
      {object: record, id: 'record_date', name: 'record[date]', format: :bridge_test}
    )
    datetime_html = active_scaffold_input_date_picker(
      config.columns[:datetime],
      {object: record, id: 'record_datetime', name: 'record[datetime]', format: :bridge_test}
    )

    assert_includes date_html, 'value="20/11/2026"'
    assert_includes date_html, 'data-dateFormat="dd/mm/yy"'
    assert_includes datetime_html, 'value="20/11/2026 12:30"'
    assert_includes datetime_html, 'data-dateFormat="dd/mm/yy"'
    assert_includes datetime_html, 'data-timeFormat="HH:mm"'
  end
end
