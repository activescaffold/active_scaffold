# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold_config_mock'

class DateTimeModel < ActiveRecord::Base
  include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model

  def self.columns
    @columns ||= [ColumnMock.new('id', '', 'int(11)'), ColumnMock.new('run_at', '', 'datetime')]
  end

  def self.columns_hash
    @columns_hash ||= columns.index_by(&:name)
  end

  def self.load_schema!
    columns_hash.each do |name, column|
      define_attribute(
        name,
        column.send(:cast_type),
        default: column.default
      )
    end
  end
end

class ParseDatetimeTest < ActiveSupport::TestCase
  include ActiveScaffoldConfigMock
  include ActiveScaffold::AttributeParams
  include ActiveScaffold::Finder

  def setup
    ActiveScaffold::Bridges::DatePicker.install
    DateTimeModel.load_schema!
    spanish = {
      time: {
        formats: {picker: '%a, %d %b %Y %H:%M:%S'}
      },
      date: {
        day_names: %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado],
        abbr_day_names: %w[Dom Lun Mar Mié Jue Vie Sáb],
        month_names: [nil, 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
        abbr_month_names: [nil, 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
        formats: {default: '%Y-%m-%d', long: '%d de %B de %Y'}
      }
    }
    I18n.backend.store_translations :es, spanish

    @config = config_for('date_time_model')
  end

  def test_trend_rejects_unsupported_units_without_dispatching_them
    Integer.any_instance.expects(:exit!).never
    Integer.any_instance.expects(:sleep).never
    column = @config.columns[:run_at]
    units = ['exit!', 'sleep', 'send', 'to_s', '', nil, ['DAYS']]
    %w[PAST FUTURE].each do |direction|
      units.each do |unit|
        assert_nil self.class.condition_for_column(column, {'opt' => direction, 'number' => '1', 'unit' => unit}, :full, {})
      end
    end
  end

  def test_trend_supports_date_and_time_units
    now = Time.zone.local(2026, 11, 23, 12)
    self.class.stubs(:datetime_now).returns(now)
    column = @config.columns[:run_at]
    directions = %w[PAST FUTURE]

    (ActiveScaffold::Finder::DATE_UNITS + ActiveScaffold::Finder::TIME_UNITS).each do |unit|
      duration = 2.public_send(unit.downcase)
      directions.each do |direction|
        expected = direction == 'PAST' ? [now.ago(duration), now] : [now, now.in(duration)]
        assert_equal expected, self.class.datetime_from_to_for_trend(column, {'opt' => direction, 'number' => '2', 'unit' => unit})
      end
    end
  end

  def test_trend_preserves_singular_and_lowercase_units
    column = @config.columns[:run_at]
    value = {'opt' => 'PAST', 'number' => '1'}
    self.class.stubs(:datetime_now).returns(Time.zone.local(2026, 11, 23, 12))

    assert_equal self.class.datetime_from_to_for_trend(column, value.merge('unit' => 'DAYS')),
                 self.class.datetime_from_to_for_trend(column, value.merge('unit' => 'day'))
  end

  def test_translate_to_english
    I18n.with_locale :es do
      assert_equal 'Mon, 03 Apr 2017 16:30:26', translate_datetime('Lun, 03 Abr 2017 16:30:26')
      assert_equal 'Fri, 24 Mar 2017 16:30:26', translate_datetime('Vie, 24 Mar 2017 16:30:26')
      assert_equal 'Tue, 28 Mar 2017 16:30:26', translate_datetime('Mar, 28 Mar 2017 16:30:26')
    end
  end

  def test_translate_to_english_with_different_order
    I18n.with_locale :es do
      format = '%d %b %Y, %a, %H:%M:%S'
      assert_equal '03 Apr 2017, Mon, 16:30:26', translate_datetime('03 Abr 2017, Lun, 16:30:26', format)
      assert_equal '24 Mar 2017, Fri, 16:30:26', translate_datetime('24 Mar 2017, Vie, 16:30:26', format)
      assert_equal '28 Mar 2017, Tue, 16:30:26', translate_datetime('28 Mar 2017, Mar, 16:30:26', format)
    end
  end

  def test_translate_to_english_with_words
    I18n.with_locale :es do
      format = '%A, %d de %B %Y, %H:%M:%S'
      assert_equal 'Monday, 03 de April de 2017, 16:30:26', translate_datetime('Lunes, 03 de Abril de 2017, 16:30:26', format)
      assert_equal 'Friday, 24 de March de 2017, 16:30:26', translate_datetime('Viernes, 24 de Marzo de 2017, 16:30:26', format)
      assert_equal 'Tuesday, 28 de March de 2017, 16:30:26', translate_datetime('Martes, 28 de Marzo de 2017, 16:30:26', format)
    end
  end

  def test_condition_for_spanish_datetime
    I18n.with_locale :es do
      assert_equal Time.zone.local(2017, 4, 3, 16, 30, 26), condition_value('Lun, 03 Abr 2017 16:30:26', :datetime_picker)
      assert_equal Time.zone.local(2017, 3, 24, 16, 30, 26), condition_value('Vie, 24 Mar 2017 16:30:26', :datetime_picker)
      assert_equal Time.zone.local(2017, 3, 28, 16, 30, 26), condition_value('Mar, 28 Mar 2017 16:30:26', :datetime_picker)
    end
  end

  def test_condition_for_english_datetime
    assert_equal Time.zone.local(2017, 4, 3, 16, 30, 26), condition_value('Mon, 03 Apr 2017 16:30:26', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 24, 16, 30, 26), condition_value('Fri, 24 Mar 2017 16:30:26', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 28, 16, 30, 26), condition_value('Tue, 28 Mar 2017 16:30:26', :datetime_picker)
  end

  def test_condition_for_english_datetime_without_time
    assert_equal Time.zone.local(2017, 4, 3, 0, 0, 0), condition_value('Mon, 03 Apr 2017', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 24, 0, 0, 0), condition_value('Fri, 24 Mar 2017', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 28, 0, 0, 0), condition_value('Tue, 28 Mar 2017', :datetime_picker)
  end

  def test_condition_for_default_datetime_without_time
    assert_equal Time.zone.local(2017, 4, 3, 0, 0, 0), condition_value('2017-04-03', :datetime)
    assert_equal Time.zone.local(2017, 3, 24, 0, 0, 0), condition_value('2017-03-24', :datetime)
    assert_equal Time.zone.local(2017, 3, 28, 0, 0, 0), condition_value('2017-03-28', :datetime)
  end

  def test_condition_for_english_datetime_without_seconds
    assert_equal Time.zone.local(2017, 4, 3, 16, 30), condition_value('Mon, 03 Apr 2017 16:30', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 24, 16, 30), condition_value('Fri, 24 Mar 2017 16:30', :datetime_picker)
    assert_equal Time.zone.local(2017, 3, 28, 16, 30), condition_value('Tue, 28 Mar 2017 16:30', :datetime_picker)
  end

  def test_condition_for_default_datetime_without_seconds
    assert_equal Time.zone.local(2017, 4, 3, 16, 30, 0), condition_value('2017-04-03 16:30', :datetime)
    assert_equal Time.zone.local(2017, 3, 24, 16, 30, 0), condition_value('2017-03-24 16:30', :datetime)
    assert_equal Time.zone.local(2017, 3, 28, 16, 30, 0), condition_value('2017-03-28 16:30', :datetime)
  end

  def test_condition_for_time
    assert_equal Time.current.change(hour: 16, min: 30), condition_value('16:30')
    assert_equal Time.current.change(hour: 16, min: 30, sec: 26), condition_value('16:30:26')
  end

  def test_condition_for_datetime_with_zone
    assert_equal ActiveSupport::TimeZone[3].local(2017, 4, 8, 16, 30, 0), condition_value('2017-04-08 16:30 +0300', :datetime)
  end

  def test_condition_for_time_with_zone_preserves_its_offset
    Time.use_zone('Madrid') do
      value = Time.zone.local(2017, 4, 8, 16, 30)

      result = condition_value(value)

      assert_instance_of Time, result
      assert_equal value, result
      assert_equal value.utc_offset, result.utc_offset
    end
  end

  def test_range_and_trend_convert_datetime_bounds_to_time
    Time.use_zone('Madrid') do
      now = Time.zone.local(2017, 4, 8, 16, 30)
      self.class.stubs(:datetime_now).returns(now)
      column = @config.columns[:run_at]

      range = self.class.datetime_from_to(column, 'opt' => 'RANGE', 'range' => 'TODAY')
      trend = self.class.datetime_from_to(column, 'opt' => 'PAST', 'number' => '2', 'unit' => 'HOURS')

      assert_equal [Time, Time], range.map(&:class)
      assert_equal [Time, Time], trend.map(&:class)
      assert_equal now.utc_offset, range.first.utc_offset
      assert_equal now.utc_offset, trend.last.utc_offset
    end
  end

  def test_range_converts_date_column_bounds_to_date
    column = ContactsController.active_scaffold_config.columns[:birthday]
    self.class.stubs(:datetime_now).returns(Time.zone.local(2017, 4, 8, 16, 30))

    values = self.class.datetime_from_to(column, 'opt' => 'RANGE', 'range' => 'TODAY')

    assert_equal [Date.new(2017, 4, 8), Date.new(2017, 4, 8)], values
  end

  def test_condition_value_accepts_multiparameter_hash_and_iso8601
    column = @config.columns[:run_at]

    hash_value = {year: '2017', month: '4', day: '8', hour: '16', minute: '30', second: '20'}
    assert_equal Time.zone.local(2017, 4, 8, 16, 30, 20),
                 self.class.condition_value_for_datetime(column, hash_value)
    assert_equal Time.zone.parse('2017-04-08T16:30:00+03:00'),
                 self.class.condition_value_for_datetime(column, '2017-04-08T16:30:00+03:00')
  end

  def test_invalid_date_time_values_return_nil
    column = @config.columns[:run_at]
    Rails.logger.expects(:warn).at_least_once

    assert_nil self.class.condition_value_for_datetime(column, 'not a time')
    assert_nil self.class.parse_date_with_format('not a date', ['%Y-%m-%d'])
    assert_nil self.class.local_time_from_hash({year: '0', month: '0', day: '0'})
  end

  def test_datetime_column_conditions
    column = ActiveScaffold::DataStructures::Column.new(:run_at, DateTimeModel)

    between = self.class.condition_for_column(
      column, {'opt' => 'BETWEEN', 'from' => '2017-04-08T10:00:00', 'to' => '2017-04-08T12:00:00'}, :full, {}
    )
    greater_than = self.class.condition_for_column(
      column, {'opt' => '>', 'from' => '2017-04-08T10:00:00'}, :full, {}
    )
    null = self.class.condition_for_column(column, {'opt' => 'null'}, :full, {})

    assert_equal '"date_time_models"."run_at" BETWEEN ? AND ?', between.first
    assert_equal [Time.zone.local(2017, 4, 8, 10), Time.zone.local(2017, 4, 8, 12)], between.drop(1)
    assert_equal ['"date_time_models"."run_at" > ?', Time.zone.local(2017, 4, 8, 10)], greater_than
    assert_equal ['"date_time_models"."run_at" is null', []], null
  end

  def test_datetime_condition_supports_search_sql_proc
    column = ActiveScaffold::DataStructures::Column.new(:run_at, DateTimeModel)
    column.search_sql = proc { |from, to, operator| [from, to, operator] }

    result = self.class.condition_for_datetime(
      column, {'opt' => '>', 'from' => '2017-04-08T10:00:00'}
    )

    assert_equal [Time.zone.local(2017, 4, 8, 10), nil, '>'], result
  end

  def test_date_trends_use_whole_days_while_datetime_trends_use_exact_times
    now = Time.zone.local(2017, 4, 8, 16, 30)
    self.class.stubs(:datetime_now).returns(now)
    date_column = ContactsController.active_scaffold_config.columns[:birthday]
    datetime_column = @config.columns[:run_at]

    assert_equal [now.beginning_of_day.ago(2.days), now.end_of_day],
                 self.class.datetime_from_to_for_trend(date_column, 'opt' => 'PAST', 'number' => '2', 'unit' => 'DAYS')
    assert_equal [now.beginning_of_day, now.end_of_day.in(2.days)],
                 self.class.datetime_from_to_for_trend(date_column, 'opt' => 'FUTURE', 'number' => '2', 'unit' => 'DAYS')
    assert_equal [now.ago(2.hours), now],
                 self.class.datetime_from_to_for_trend(datetime_column, 'opt' => 'PAST', 'number' => '2', 'unit' => 'HOURS')
    assert_equal [now, now.in(2.hours)],
                 self.class.datetime_from_to_for_trend(datetime_column, 'opt' => 'FUTURE', 'number' => '2', 'unit' => 'HOURS')
  end

  def test_named_and_relative_date_ranges
    now = Time.zone.local(2017, 4, 8, 16, 30)
    self.class.stubs(:datetime_now).returns(now)
    column = @config.columns[:run_at]

    assert_equal [now.yesterday.beginning_of_day, now.yesterday.end_of_day],
                 self.class.datetime_from_to_for_range(column, 'range' => 'YESTERDAY')
    assert_equal [now.tomorrow.beginning_of_day, now.tomorrow.end_of_day],
                 self.class.datetime_from_to_for_range(column, 'range' => 'TOMORROW')
    assert_equal [now.ago(1.week).beginning_of_week, now.ago(1.week).end_of_week],
                 self.class.datetime_from_to_for_named_range('PREV_WEEK')
    assert_equal [now.in(1.month).beginning_of_month, now.in(1.month).end_of_month],
                 self.class.datetime_from_to_for_named_range('NEXT_MONTH')
    assert_equal [nil, nil], self.class.datetime_from_to_for_named_range('OTHER_YEAR')
    assert_raises(ArgumentError) { self.class.datetime_from_to_for_named_range('THIS_DAY') }
  end

  def test_condition_for_spanish_date
    @config.columns[:run_at].options[:format] = :long
    I18n.with_locale :es do
      assert_equal Date.new(2017, 4, 3), condition_value('03 de Abril de 2017', :date_picker, :to_date)
      assert_equal Date.new(2017, 3, 24), condition_value('24 de Marzo de 2017', :date_picker, :to_date)
      assert_equal Date.new(2017, 3, 28), condition_value('28 de Marzo de 2017', :date_picker, :to_date)
    end
  end

  def test_condition_for_english_date
    @config.columns[:run_at].options[:format] = :long
    assert_equal Date.new(2017, 4, 3), condition_value('April 03, 2017', :date_picker, :to_date)
    assert_equal Date.new(2017, 3, 24), condition_value('March 24, 2017', :date_picker, :to_date)
    assert_equal Date.new(2017, 3, 28), condition_value('March 28, 2017', :date_picker, :to_date)
  end

  private

  def translate_datetime(value, format = nil)
    format ||= I18n.t('time.formats.picker')
    self.class.translate_days_and_months(value, format)
  end

  def condition_value(value, ui_name = nil, conversion = nil)
    old_ui = @config.columns[:run_at].search_ui
    @config.columns[:run_at].search_ui = ui_name if ui_name
    self.class.condition_value_for_datetime(@config.columns[:run_at], value, conversion || :to_time).tap do
      @config.columns[:run_at].search_ui = old_ui
    end
  end

  def params_hash?(value)
    value.is_a? Hash
  end
end
