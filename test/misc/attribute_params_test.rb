require File.join(File.dirname(__FILE__), '../test_helper.rb')

class NumberModel < ActiveRecord::Base
  abstract_class = true
  def self.columns
    @columns ||= [ActiveRecord::ConnectionAdapters::Column.new('number', '', 'double(10,2)')]
  end
end

class AttributeParamsTest < Test::Unit::TestCase
  include ActiveScaffold::AttributeParams

  def setup
    I18n.backend.store_translations :en, :number => {:format => {
      :delimiter => ',',
      :separator => '.'
    }}
    I18n.backend.store_translations :es, :number => {:format => {
      :delimiter => '.',
      :separator => ','
    }}
    I18n.backend.store_translations :ru, :number => {:currency => {
      :format => {
        :separator => ',',
        :delimiter => ''
      }
    }}

    @config = config_for('number_model')
    class << @config.list.columns
      include ActiveScaffold::DataStructures::ActionColumns::AfterConfiguration
    end
    @config.list.columns.set_columns @config.columns
  end

  def teardown
    I18n.locale = :en
  end

  def test_english_format_with_decimal_separator_using_english_language
    I18n.locale = :en
    assert_equal 0.1, convert_number('.1')
    assert_equal 0.1, convert_number('.100')
    assert_equal 0.1, convert_number('0.1')
    assert_equal 0.345, convert_number('0.345')
    assert_equal 0.345, convert_number('+0.345')
    assert_equal -0.345, convert_number('-0.345')
    assert_equal 9.345, convert_number('9.345')
    assert_equal 9.1, convert_number('9.1')
    assert_equal 90.1, convert_number('90.1')
  end

  def test_english_format_with_thousand_delimiter_using_english_language
    I18n.locale = :en
    assert_equal 1000, convert_number('1,000')
    assert_equal 1000, convert_number('+1,000')
    assert_equal -1000, convert_number('-1,000')
    assert_equal 1000000, convert_number('1,000,000')
  end

  def test_english_format_with_separator_and_delimiter_using_english_language
    I18n.locale = :en
    assert_equal 1234.1, convert_number('1,234.1')
    assert_equal 1234.1, convert_number('1,234.100')
    assert_equal 1234.345, convert_number('+1,234.345')
    assert_equal -1234.345, convert_number('-1,234.345')
    assert_equal 1234000.1, convert_number('1,234,000.100')
  end

  def test_english_format_with_decimal_separator_using_spanish_language
    I18n.locale = :es
    assert_equal 0.1, convert_number('.1')
    assert_equal 0.1, convert_number('0.1')
    assert_equal 0.12, convert_number('+0.12')
    assert_equal -0.12, convert_number('-0.12')
    assert_equal 9.1, convert_number('9.1')
    assert_equal 90.1, convert_number('90.1')
  end

  def test_spanish_format_with_decimal_separator_using_spanish_language
    I18n.locale = :es
    assert_equal 0.1, convert_number(',1')
    assert_equal 0.1, convert_number(',100')
    assert_equal 0.1, convert_number('0,1')
    assert_equal 0.345, convert_number('0,345')
    assert_equal 0.345, convert_number('+0,345')
    assert_equal -0.345, convert_number('-0,345')
    assert_equal 9.1, convert_number('9,1')
    assert_equal 90.1, convert_number('90,1')
    assert_equal 9.1, convert_number('9,100')
  end

  def test_spanish_format_with_thousand_delimiter_using_spanish_language
    I18n.locale = :es
    assert_equal 1000, convert_number('1.000')
    assert_equal 1000, convert_number('+1.000')
    assert_equal -1000, convert_number('-1.000')
    assert_equal 1000000, convert_number('1.000.000')
  end

  def test_spanish_format_with_separator_and_decimal_using_spanish_language
    I18n.locale = :es
    assert_equal 1230.1, convert_number('1.230,1')
    assert_equal 1230.1, convert_number('1.230,100')
    assert_equal 1234.345, convert_number('+1.234,345')
    assert_equal -1234.345, convert_number('-1.234,345')
    assert_equal 1234000.1, convert_number('1.234.000,100')
  end

  def test_english_currency_format_with_decimal_separator_using_russian_language
    I18n.locale = :ru
    assert_equal 0.1, convert_number('.1', :currency)
    assert_equal 0.1, convert_number('0.1', :currency)
    assert_equal 0.12, convert_number('+0.12', :currency)
    assert_equal -0.12, convert_number('-0.12', :currency)
    assert_equal 9.1, convert_number('9.1', :currency)
    assert_equal 90.1, convert_number('90.1', :currency)
  end

  def test_russian_currency_format_with_decimal_separator_using_russian_language
    I18n.locale = :ru
    assert_equal 0.1, convert_number(',1', :currency)
    assert_equal 0.1, convert_number(',100', :currency)
    assert_equal 0.1, convert_number('0,1', :currency)
    assert_equal 0.345, convert_number('0,345', :currency)
    assert_equal 0.345, convert_number('+0,345', :currency)
    assert_equal -0.345, convert_number('-0,345', :currency)
    assert_equal 9.1, convert_number('9,1', :currency)
    assert_equal 90.1, convert_number('90,1', :currency)
    assert_equal 9.1, convert_number('9,100', :currency)
  end

  def test_english_format_with_decimal_separator_with_no_localized_format
    I18n.locale = :ru
    assert_equal 0.1, convert_number('.1')
    assert_equal 0.1, convert_number('0.1')
  end

  private
  def convert_number(value, format = nil)
    record = NumberModel.new
    @config.columns[:number].options[:format] = format unless format.nil?
    update_record_from_params(record, @config.list.columns, HashWithIndifferentAccess.new({:number => value}))
    record.number
  end
end
