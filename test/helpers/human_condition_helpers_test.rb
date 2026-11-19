# frozen_string_literal: true

require 'test_helper'

class HumanConditionHelpersTest < ActiveSupport::TestCase
  include ActiveScaffold::Helpers::HumanConditionHelpers

  def setup
    @field_search_params = {}
    stubs(:field_search_params).returns(@field_search_params)
    stubs(:override_helper).returns(nil)
  end

  def test_dispatches_a_condition_by_column_type
    column = condition_column(:age, 'Age', column_type: :integer)
    @field_search_params['age'] = {'opt' => '>=', 'from' => '21'}
    numeric_controller = Class.new do
      def self.condition_value_for_numeric(_column, value)
        value.to_i
      end
    end
    stubs(:controller).returns(numeric_controller.new)
    stubs(:format_number_value).with(21, {}).returns('21')

    assert_equal 'Age >= 21 ', active_scaffold_human_condition_for(column)
  end

  def test_uses_a_column_override_and_warns_for_an_unknown_search_ui
    column = condition_column(:name, 'Name', search_ui: :custom)
    @field_search_params['name'] = 'Alice'
    stubs(:override_helper).with(column, 'human_condition_column').returns(:name_human_condition)
    define_singleton_method(:name_human_condition) { |value, options| [value, options] }

    assert_equal ['Alice', {}], active_scaffold_human_condition_for(column)

    stubs(:override_helper).returns(nil)
    logger = mock
    logger.expects(:warn).with(includes('search_ui custom', 'column name'))
    stubs(:logger).returns(logger)
    assert_nil active_scaffold_human_condition_for(column)
  end

  def test_formats_grouped_by_and_numeric_between_conditions
    group_options = [%w[Month month], %w[Year year]]
    config = stub(field_search: stub(group_options: group_options))
    column = condition_column(:amount, 'Amount')
    @field_search_params['active_scaffold_group'] = 'year'
    stubs(:active_scaffold_config).returns(config)
    stubs(:active_scaffold_group_column).returns(column)
    stubs(:active_scaffold_translated_option).with(column, 'Year').returns(['Translated year'])

    assert_equal 'Translated year', active_scaffold_grouped_by_label

    numeric_controller = Class.new do
      def self.condition_value_for_numeric(_column, value)
        value.to_i
      end
    end
    stubs(:controller).returns(numeric_controller.new)
    stubs(:format_number_value).with(10, {}).returns('10')
    stubs(:format_number_value).with(20, {}).returns('20')
    value = {'opt' => 'BETWEEN', 'from' => '10', 'to' => '20'}
    assert_equal 'Amount between 10 - 20', active_scaffold_human_condition_integer(column, value)
  end

  def test_formats_each_datetime_condition_shape
    from = Time.zone.local(2026, 1, 5, 10)
    to = Time.zone.local(2026, 1, 6, 10)
    datetime_controller = Class.new
    datetime_controller.define_singleton_method(:datetime_from_to) { |_column, _value| [from, to] }
    stubs(:controller).returns(datetime_controller.new)
    column = condition_column(:created_at, 'Created at')

    range = {'opt' => 'RANGE', 'range' => 'current_month'}
    assert_equal 'Created at = current_month (Jan 2026)', active_scaffold_human_condition_datetime(column, range)

    between = {'opt' => 'BETWEEN'}
    expected = "Created at between #{I18n.l(from)} - #{I18n.l(to)}"
    assert_equal expected, active_scaffold_human_condition_datetime(column, between)
    assert_equal 'Created at not_null', active_scaffold_human_condition_datetime(column, 'opt' => 'not_null')
    expected = "Created at >= #{I18n.l(from)}"
    assert_equal expected, active_scaffold_human_condition_datetime(column, 'opt' => '>=')
  end

  def test_select_conditions_use_association_and_configured_option_labels
    admin = Role.create!(name: 'Admin')
    association = stub(klass: Role)
    role_column = condition_column(:roles, 'Roles', association: association, options: {label_method: :name})
    expects(:as_).with(:association, scope: :human_conditions, column: 'Roles', value: 'Admin').returns('Roles: Admin')
    assert_equal 'Roles: Admin', active_scaffold_human_condition_select(role_column, [admin.id.to_s])

    status_column = condition_column(
      :status,
      'Status',
      options: {options: [['Enabled', 1], ['Disabled', nil]]}
    )
    expects(:active_scaffold_translated_option)
      .with(status_column, 'Enabled', 1)
      .returns(['Translated Enabled'])
    expects(:active_scaffold_translated_option)
      .with(status_column, 'Disabled', nil)
      .returns(['Translated Disabled'])
    expects(:as_).with(
      :association,
      scope: :human_conditions,
      column: 'Status',
      value: 'Translated Enabled, Translated Disabled, unknown'
    ).returns('statuses')

    assert_equal 'statuses', active_scaffold_human_condition_select(status_column, %w[1 Disabled unknown])
  end

  def test_boolean_null_and_non_equality_select_conditions
    column = condition_column(:active, 'Active')
    expects(:as_).with(true).returns('yes')
    expects(:as_).with(:boolean, scope: :human_conditions, column: 'Active', value: 'yes').returns('Active is yes')
    assert_equal 'Active is yes', active_scaffold_human_condition_boolean(column, true)
    unstub(:as_)
    assert_equal 'Active null  ', active_scaffold_human_condition_null(column, 'null')

    value = {'opt' => 'BETWEEN', 'from' => 'a', 'to' => 'z'}
    assert_equal "Active between 'a' - z", active_scaffold_human_condition_select(column, value)
  end

  def test_datetime_range_formats_cover_week_month_year_and_default
    I18n.stubs(:t).with('active_scaffold.date_picker_options.firstDay').returns(1)
    I18n.stubs(:t).with('date.formats.default').returns('%Y-%m-%d')
    assert_equal '%W %Y', active_scaffold_human_condition_datetime_range_format('current', 'week')
    assert_equal '%b %Y', active_scaffold_human_condition_datetime_range_format('current', 'month')
    assert_equal '%Y', active_scaffold_human_condition_datetime_range_format('current', 'year')
    assert_equal '%Y-%m-%d', active_scaffold_human_condition_datetime_range_format('current', 'day')
  end

  private

  def as_(value, **)
    value.to_s
  end

  def condition_column(name, label, column_type: nil, search_ui: nil, association: nil, options: {})
    stub(
      name: name,
      label: label,
      column: !column_type.nil?,
      column_type: column_type,
      search_ui: search_ui,
      association: association,
      options: options
    )
  end
end
