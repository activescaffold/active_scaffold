# frozen_string_literal: true

require 'test_helper'

class SearchColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormUiHelpers
  include ActiveScaffold::Helpers::SearchColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers
  include ERB::Util

  def setup
    RequestStore.clear!
    @column = ActiveScaffold::DataStructures::Column.new(:adult, Person)
    @record = Person.new
    @field_search_params = {}
  end

  def teardown
    RequestStore.clear!
    super
  end

  def adult_search_column(_record, _options)
    content_tag(:span, 'search override', class: 'search-override')
  end

  def first_name_form_column(_record, _options)
    content_tag(:span, 'shared form override', class: 'form-override')
  end

  def test_choices_for_boolean_search_ui
    opts = {object: @record, name: 'search[adult]', value: '0'}
    assert_dom_equal "<select name=\"search[adult]\"><option value=\"\">- select -</option>\n<option value=\"true\">True</option>\n<option value=\"false\" selected=\"selected\">False</option></select>", active_scaffold_search_boolean(@column, opts)
  end

  def test_boolean_search_ui_for_nullable_column_includes_null
    @column.stubs(:null?).returns(true)

    fragment = Nokogiri::HTML.fragment(
      active_scaffold_search_boolean(@column, {name: 'search[adult]', value: 'null'})
    )

    assert_equal 'null', fragment.at_css('option[value="null"][selected="selected"]')['value']
    assert_equal ['', 'null', 'true', 'false'], fragment.css('option').pluck('value')
  end

  def test_multi_select_search_uses_explicit_empty_association_conditions
    association = stub
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_multi_select(@column, {object: @record, value: nil})
  end

  def test_multi_select_search_renders_nonempty_association_options
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    selected = Category.new(id: 10, name: 'Selected')
    available = Category.new(id: 20, name: 'Available')
    selected.define_singleton_method(:to_label) { name }
    available.define_singleton_method(:to_label) { name }
    stubs(:association_helper_method).with(
      column.association, :sorted_association_options_find
    ).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(column.association, {}, instance_of(Task)).returns(
      [selected, available]
    )

    html = active_scaffold_search_multi_select(
      column,
      {object: Task.new, value: ['10'], name: 'search[category]', id: 'search_category', class: 'category-input'}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('input[type="checkbox"][value="10"][checked="checked"]')
    assert fragment.at_css('input[type="checkbox"][value="20"]')
    assert_includes fragment.text, 'Selected'
    assert_includes fragment.text, 'Available'
  end

  def test_multi_select_search_ui_for_non_association_column
    column = ActiveScaffold::DataStructures::Column.new(:last_name, Person)
    column.search_ui = [:multi_select, {options: [%w[Alpha A], %w[Beta B]]}]
    @field_search_params['last_name'] = ['B']
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    fragment = Nokogiri::HTML.fragment(active_scaffold_search_for(column))

    assert fragment.at_css('input[type="checkbox"][value="A"]')
    assert fragment.at_css('input[type="checkbox"][value="B"][checked="checked"]')
    assert_includes fragment.text, 'Alpha'
    assert_includes fragment.text, 'Beta'
  end

  def test_select_search_uses_explicit_empty_association_conditions
    association = stub(belongs_to?: false)
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_select(@column, {object: @record, value: nil}, {}, ui_options: {null_comparators: false})
  end

  def test_select_search_renders_optgroups_and_null_comparators
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    first_time = Time.utc(2026, 1, 1)
    second_time = Time.utc(2026, 2, 1)
    first = Category.new(id: 10, name: 'First', created_at: first_time)
    second = Category.new(id: 20, name: 'Second', created_at: second_time)
    first.define_singleton_method(:to_label) { name }
    second.define_singleton_method(:to_label) { name }
    column.options[:optgroup] = :created_at
    @field_search_params['category'] = {'opt' => 'null', 'from' => '10'}
    columns = ActiveSupport::HashWithIndifferentAccess.new(category_id: stub(null?: true))
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false), columns: columns))
    stubs(:active_scaffold_config_for).with(Category).returns(config_for(Category))
    stubs(:association_helper_method).with(
      column.association, :sorted_association_options_find
    ).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(column.association, {}, instance_of(Task)).returns([first, second])

    fragment = Nokogiri::HTML.fragment(
      active_scaffold_search_for(
        column, object: Task.new, name: 'search[category]', id: 'search_category'
      )
    )

    assert fragment.at_css('option[value="null"][selected="selected"]')
    assert fragment.at_css('select[name="search[category][from]"]')
    assert_equal [first_time.to_s, second_time.to_s], fragment.css('optgroup').pluck('label')
    assert fragment.at_css('optgroup option[value="10"][selected="selected"]')
  end

  def test_field_search_renders_grouping_select
    @field_search_params['active_scaffold_group'] = 'birthday#year'
    field_search = stub(
      group_options: [['Birthday year', 'birthday#year'], ['Adult', 'adult']],
      update_columns: false
    )
    stubs(:active_scaffold_config).returns(stub(field_search: field_search, model: Person))

    html = active_scaffold_group_search_column(@record, {})
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal 1, fragment.css('select[name="search[active_scaffold_group]"]').size
    assert_equal 'No group', fragment.at_css('option[value=""]').text
    assert_equal 'Birthday year', fragment.at_css('option[value="birthday#year"][selected="selected"]').text
    assert_equal 'Adult', fragment.at_css('option[value="adult"]').text
    assert_equal 'Group by', active_scaffold_group_column.label
  end

  def test_field_search_adds_update_columns_options
    columns = stub(visible_columns_names: %i[adult first_name])
    field_search = stub(update_columns: true, columns: columns)
    stubs(:active_scaffold_config).returns(stub(field_search: field_search))
    options = {object: @record, name: 'search[adult]', id: 'search_adult'}
    updated_options = options.merge('data-update_url' => '/people/render_field')
    expects(:update_columns_options).with(
      @column, nil, options,
      form_columns: %i[adult first_name], url_params: {form_action: :field_search}
    ).returns(updated_options)

    html = active_scaffold_search_for(@column, options)

    assert_includes html, 'search-override'
  end

  def test_column_search_override_takes_priority_over_search_ui
    @column.search_ui = :boolean
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    html = active_scaffold_search_for(@column, object: @record)

    assert_includes html, 'search override'
    assert_not_includes html, '<select'
  end

  def test_column_form_override_is_shared_when_search_ui_has_no_helper
    column = ActiveScaffold::DataStructures::Column.new(:first_name, Person)
    column.search_ui = :custom
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    html = active_scaffold_search_for(column, object: @record)

    assert_includes html, 'shared form override'
  end

  def test_configured_search_ui_takes_priority_over_shared_form_override
    column = ActiveScaffold::DataStructures::Column.new(:first_name, Person)
    column.search_ui = [
      :select,
      {options: [['A names', 'A'], ['B names', 'B']], include_blank: 'Any', null_comparators: false}
    ]
    @field_search_params['first_name'] = 'B'
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    fragment = Nokogiri::HTML.fragment(active_scaffold_search_for(column))

    assert_equal 'Any', fragment.at_css('option[value=""]').text
    assert_equal 'B names', fragment.at_css('option[value="B"][selected="selected"]').text
    assert_nil fragment.at_css('.form-override')
  end

  def test_polymorphic_association_without_search_ui_or_override_uses_text_search
    column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)
    @field_search_params['contactable'] = 'Ada'
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    fragment = Nokogiri::HTML.fragment(active_scaffold_search_for(column))
    input = fragment.at_css('input[type="text"]')

    assert_nil column.search_ui
    assert_equal 'search[contactable]', input['name']
    assert_equal 'Ada', input['value']
  end

  def test_field_search_preserves_and_renders_column_subgroups
    config = config_for(Person)
    config.actions << :field_search
    config.field_search.columns = %i[first_name last_name]
    config.field_search.columns.add_subgroup('Identity') do |group|
      group.add :first_name
    end
    subgroup = config.field_search.columns.find { |column| column.respond_to?(:each_column) }
    stubs(:active_scaffold_config).returns(config)
    expects(:render_subsection).with(
      subgroup, @record, nil, :field_search, partial: 'field_search_columns'
    ).returns('subgroup fields')

    visibles, hiddens = visibles_and_hiddens(config.field_search)
    html = render_field_search_column(subgroup, @record)

    assert_includes visibles, subgroup
    assert_empty hiddens
    assert_includes html, 'subgroup fields'
    assert_includes html, 'identity'
  end

  def test_null_search_ui_renders_null_comparators
    column = ActiveScaffold::DataStructures::Column.new(:last_name, Person)
    column.search_ui = :null
    @field_search_params['last_name'] = 'not_null'
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))

    fragment = Nokogiri::HTML.fragment(active_scaffold_search_for(column))

    assert_equal 'not_null', fragment.at_css('option[selected="selected"]')['value']
    assert_equal %w[null not_null], fragment.css('option').pluck('value').compact_blank
  end

  def test_integer_search_ui_renders_numeric_range
    column = ActiveScaffold::DataStructures::Column.new(:buildings_count, Person)
    column.search_ui = [:integer, {min: 0, max: 20}]
    @field_search_params['buildings_count'] = {'opt' => '>=', 'from' => '2'}
    stubs(:active_scaffold_config).returns(stub(field_search: stub(update_columns: false)))
    controller.class.stubs(:condition_value_for_numeric).with(column, '2').returns(2)
    controller.class.stubs(:condition_value_for_numeric).with(column, nil).returns(nil)

    fragment = Nokogiri::HTML.fragment(active_scaffold_search_for(column))
    input = fragment.at_css('input[type="number"]')

    assert_equal '>=', fragment.at_css('option[selected="selected"]')['value']
    assert_equal 'search[buildings_count][from]', input['name']
    assert_equal '2', input['value']
    assert_equal '1', input['step']
  end

  def test_datetime_trend_units_include_time_and_date_units
    column = ActiveScaffold::DataStructures::Column.new(:created_at, Person)

    units = active_scaffold_search_datetime_trend_units(column).map(&:last)

    assert_equal ActiveScaffold::Finder::TIME_UNITS + ActiveScaffold::Finder::DATE_UNITS, units
  end

  private

  attr_reader :field_search_params
end
