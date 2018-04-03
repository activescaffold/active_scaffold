require 'test_helper'
require 'active_scaffold_config_mock'

class DateTimeModel < ActiveRecord::Base
  include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model
  def self.columns
    @columns ||= [ColumnMock.new('id', '', 'int(11)'), ColumnMock.new('run_at', '', 'datetime')]
  end

  def self.columns_hash
    @columns_hash ||= Hash[columns.map { |c| [c.name, c] }]
  end

  def self.load_schema!
    columns_hash.each do |name, column|
      define_attribute(
        name,
        connection.lookup_cast_type_from_column(column),
        default: column.default
      )
    end
  end
end

class ParseDatetimeTest < MiniTest::Test
  include ActiveScaffoldConfigMock
  include ActiveScaffold::AttributeParams
  include ActiveScaffold::Finder

  def setup
    DateTimeModel.load_schema! if Rails.version >= '5.0'
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
    @config.create.columns.set_columns @config.columns
  end

  def teardown
    I18n.locale = :en
  end

  def test_translate_to_english
    I18n.locale = :es
    assert_equal 'Mon, 03 Apr 2017 16:30:26', translate_datetime('Lun, 03 Abr 2017 16:30:26')
    assert_equal 'Fri, 24 Mar 2017 16:30:26', translate_datetime('Vie, 24 Mar 2017 16:30:26')
    assert_equal 'Tue, 28 Mar 2017 16:30:26', translate_datetime('Mar, 28 Mar 2017 16:30:26')
  end

  def test_translate_to_english_with_different_order
    I18n.locale = :es
    format = '%d %b %Y, %a, %H:%M:%S'
    assert_equal '03 Apr 2017, Mon, 16:30:26', translate_datetime('03 Abr 2017, Lun, 16:30:26', format)
    assert_equal '24 Mar 2017, Fri, 16:30:26', translate_datetime('24 Mar 2017, Vie, 16:30:26', format)
    assert_equal '28 Mar 2017, Tue, 16:30:26', translate_datetime('28 Mar 2017, Mar, 16:30:26', format)
  end

  def test_translate_to_english_with_words
    I18n.locale = :es
    format = '%A, %d de %B %Y, %H:%M:%S'
    assert_equal 'Monday, 03 de April de 2017, 16:30:26', translate_datetime('Lunes, 03 de Abril de 2017, 16:30:26', format)
    assert_equal 'Friday, 24 de March de 2017, 16:30:26', translate_datetime('Viernes, 24 de Marzo de 2017, 16:30:26', format)
    assert_equal 'Tuesday, 28 de March de 2017, 16:30:26', translate_datetime('Martes, 28 de Marzo de 2017, 16:30:26', format)
  end

  def test_condition_for_spanish_datetime
    with_js_framework :jquery do
      I18n.locale = :es
      assert_equal Time.zone.local(2017, 4, 3, 16, 30, 26), condition_value('Lun, 03 Abr 2017 16:30:26')
      assert_equal Time.zone.local(2017, 3, 24, 16, 30, 26), condition_value('Vie, 24 Mar 2017 16:30:26')
      assert_equal Time.zone.local(2017, 3, 28, 16, 30, 26), condition_value('Mar, 28 Mar 2017 16:30:26')
    end
  end

  def test_condition_for_english_datetime
    with_js_framework :jquery do
      assert_equal Time.zone.local(2017, 4, 3, 16, 30, 26), condition_value('Mon, 03 Apr 2017 16:30:26')
      assert_equal Time.zone.local(2017, 3, 24, 16, 30, 26), condition_value('Fri, 24 Mar 2017 16:30:26')
      assert_equal Time.zone.local(2017, 3, 28, 16, 30, 26), condition_value('Tue, 28 Mar 2017 16:30:26')
    end
  end

  def test_condition_for_english_datetime_without_time
    with_js_framework :jquery do
      assert_equal Time.zone.local(2017, 4, 3, 0, 0, 0), condition_value('Mon, 03 Apr 2017')
      assert_equal Time.zone.local(2017, 3, 24, 0, 0, 0), condition_value('Fri, 24 Mar 2017')
      assert_equal Time.zone.local(2017, 3, 28, 0, 0, 0), condition_value('Tue, 28 Mar 2017')
    end
  end

  def test_condition_for_default_datetime_without_time
    assert_equal Time.zone.local(2017, 4, 3, 0, 0, 0), condition_value('2017-04-03')
    assert_equal Time.zone.local(2017, 3, 24, 0, 0, 0), condition_value('2017-03-24')
    assert_equal Time.zone.local(2017, 3, 28, 0, 0, 0), condition_value('2017-03-28')
  end

  def test_condition_for_english_datetime_without_seconds
    with_js_framework :jquery do
      assert_equal Time.zone.local(2017, 4, 3, 16, 30), condition_value('Mon, 03 Apr 2017 16:30')
      assert_equal Time.zone.local(2017, 3, 24, 16, 30), condition_value('Fri, 24 Mar 2017 16:30')
      assert_equal Time.zone.local(2017, 3, 28, 16, 30), condition_value('Tue, 28 Mar 2017 16:30')
    end
  end

  def test_condition_for_default_datetime_without_seconds
    assert_equal Time.zone.local(2017, 4, 3, 16, 30, 0), condition_value('2017-04-03 16:30')
    assert_equal Time.zone.local(2017, 3, 24, 16, 30, 0), condition_value('2017-03-24 16:30')
    assert_equal Time.zone.local(2017, 3, 28, 16, 30, 0), condition_value('2017-03-28 16:30')
  end

  def test_condition_for_time
    assert_equal Time.current.change(hour: 16, min: 30), condition_value('16:30')
    assert_equal Time.current.change(hour: 16, min: 30, sec: 26), condition_value('16:30:26')
  end

  def test_condition_for_datetime_with_zone
    assert_equal ActiveSupport::TimeZone[3].local(2017, 4, 8, 16, 30, 0), condition_value('2017-04-08 16:30 +0300')
  end

  def test_condition_for_spanish_date
    @config.columns[:run_at].options[:format] = :long
    I18n.locale = :es
    assert_equal Date.new(2017, 4, 3), condition_value('03 de Abril de 2017', :to_date)
    assert_equal Date.new(2017, 3, 24), condition_value('24 de Marzo de 2017', :to_date)
    assert_equal Date.new(2017, 3, 28), condition_value('28 de Marzo de 2017', :to_date)
  end

  def test_condition_for_english_date
    @config.columns[:run_at].options[:format] = :long
    assert_equal Date.new(2017, 4, 3), condition_value('April 03, 2017', :to_date)
    assert_equal Date.new(2017, 3, 24), condition_value('March 24, 2017', :to_date)
    assert_equal Date.new(2017, 3, 28), condition_value('March 28, 2017', :to_date)
  end

  private

  def translate_datetime(value, format = nil)
    format ||= I18n.t('time.formats.picker')
    self.class.translate_days_and_months(value, format)
  end

  def condition_value(value, conversion = nil)
    self.class.condition_value_for_datetime(@config.columns[:run_at], value, conversion || :to_time)
  end

  def params_hash?(value)
    value.is_a? Hash
  end
end
