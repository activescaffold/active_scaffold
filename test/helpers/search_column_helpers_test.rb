# frozen_string_literal: true

require 'test_helper'

class SearchColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormUiHelpers
  include ActiveScaffold::Helpers::SearchColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

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

  def test_multi_select_search_uses_explicit_empty_association_conditions
    association = stub
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_multi_select(@column, {object: @record, value: nil})
  end

  def test_select_search_uses_explicit_empty_association_conditions
    association = stub(belongs_to?: false)
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_select(@column, {object: @record, value: nil}, {}, ui_options: {null_comparators: false})
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

  private

  attr_reader :field_search_params
end
