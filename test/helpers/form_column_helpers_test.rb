# frozen_string_literal: true

require 'test_helper'

class FormColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @record = ModelStub.new(a: nil)
  end

  def a_form_column(*)
    content_tag(:input, nil, name: 'record[a]').freeze
  end

  def test_form_attribute_html_does_not_modify_frozen_custom_form_column
    field = active_scaffold_render_input(@column, object: @record)
    description = content_tag(:span, 'Description')

    assert_predicate field, :frozen?
    assert_dom_equal '<dl><dt>Label</dt><dd><input name="record[a]"><span>Description</span></dd></dl>',
                     form_attribute_html(@column, 'Label', field, description, {})
  end

  def test_choices_for_select_form_ui_for_simple_column
    opts = {object: @record}
    @column.options[:options] = %i[value_1 value_2 value_3]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">Value 1</option>\n<option value=\"value_2\">Value 2</option>\n<option value=\"value_3\">Value 3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = %w[value_1 value_2 value_3]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">value_1</option>\n<option value=\"value_2\">value_2</option>\n<option value=\"value_3\">value_3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = [%w[text_1 value_1], %w[text_2 value_2], %w[text_3 value_3]]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">text_1</option>\n<option value=\"value_2\">text_2</option>\n<option value=\"value_3\">text_3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = [%i[text_1 value_1], %i[text_2 value_2], %i[text_3 value_3]]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">Text 1</option>\n<option value=\"value_2\">Text 2</option>\n<option value=\"value_3\">Text 3</option></select>", active_scaffold_input_select(@column, opts.dup)
  end

  def test_options_for_select_form_ui_for_simple_column
    opts = {object: @record}
    @column.options = {include_blank: 'None', selected: 'value_2', disabled: %w[value_1 value_3]}
    @column.options[:options] = %w[value_1 value_2 value_3]
    @column.options[:html_options] = {class: 'big'}
    assert_dom_equal "<select name=\"record[a]\" class=\"big\" id=\"record_a\"><option value=\"\">None</option>\n<option disabled=\"disabled\" value=\"value_1\">value_1</option>\n<option selected=\"selected\" value=\"value_2\">value_2</option>\n<option disabled=\"disabled\" value=\"value_3\">value_3</option></select>", active_scaffold_input_select(@column, opts)
  end

  def test_select_form_ui_for_polymorphic_association
    person = Person.create!(first_name: 'Ada', last_name: 'Lovelace')
    unassigned_person = Person.create!(first_name: 'Grace', last_name: 'Hopper')
    record = Contact.new(contactable: person)
    column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)
    column.form_ui = :select

    html = active_scaffold_input_select(
      column,
      {object: record, name: 'record[contactable]', id: 'record_contactable'}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal person.id.to_s, fragment.at_css('option[selected="selected"]')['value']
    assert_predicate fragment.at_css('option[selected="selected"]').text, :present?
    assert_includes fragment.css('option').pluck('value'), unassigned_person.id.to_s
  ensure
    Person.delete_all
  end

  def test_select_form_ui_for_polymorphic_association_without_type
    Person.create!(first_name: 'Unassigned', last_name: 'Person')
    record = Contact.new
    column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)
    column.form_ui = :select

    html = active_scaffold_input_select(
      column,
      {object: record, name: 'record[contactable]', id: 'record_contactable'}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_nil record.contactable_type
    assert_equal [''], fragment.css('option').pluck('value')
  ensure
    Person.delete_all
  end

  def test_select_form_ui_honors_sort_by_and_hash_includes
    first = Category.create!(name: 'Alpha')
    Category.create!(name: 'Zulu')
    Task.create!(name: 'First task', category: first)
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    column.form_ui = :select
    column.sort_by sql: 'categories.name DESC'
    column.includes = [{category: :tasks}]
    @active_scaffold_configs = {Task => stub(columns: {category: column})}

    options = sorted_association_options_find(column.association, nil, Task.new)
    html = active_scaffold_input_select(
      column,
      {object: Task.new, name: 'record[category]', id: 'record_category'}
    )
    option_labels = Nokogiri::HTML.fragment(html).css('option').map(&:text).reject { |label| label == '- select -' }

    assert_equal %w[Zulu Alpha], options.map(&:name)
    assert_predicate options.last.association(:tasks), :loaded?
    assert_equal %w[Zulu Alpha], option_labels
  ensure
    Task.delete_all
    Category.delete_all
  end

  def test_select_form_ui_scopes_options_for_nested_through_association
    building = Building.create!(name: 'Headquarters')
    other_building = Building.create!(name: 'Branch office')
    person = Person.create!(first_name: 'Ada', last_name: 'Lovelace')
    selected_floor = Floor.create!(number: 1, building: building, tenant: person)
    unassigned_floor = Floor.create!(number: 2, building: building)
    other_floor = Floor.create!(number: 3, building: other_building)
    column = ActiveScaffold::DataStructures::Column.new(:floor, Person)
    column.form_ui = :select
    @nested = ActiveScaffold::DataStructures::NestedInfo.get(
      Person,
      parent_scaffold: 'buildings', association: 'tenants', building_id: building.id
    )
    @nested_parent_record = building

    html = active_scaffold_input_select(
      column,
      {object: person, name: 'record[floor]', id: 'record_floor'}
    )
    fragment = Nokogiri::HTML.fragment(html)
    option_values = fragment.css('option').pluck('value')

    assert_equal selected_floor.id.to_s, fragment.at_css('option[selected="selected"]')['value']
    assert_includes option_values, unassigned_floor.id.to_s
    assert_not_includes option_values, other_floor.id.to_s
  ensure
    Floor.delete_all
    Building.delete_all
    Person.delete_all
  end

  def test_select_form_ui_scopes_options_for_nested_through_singular_association
    building = Building.create!(name: 'Headquarters')
    person = Person.create!(first_name: 'Ada', last_name: 'Lovelace')
    through_floor = Floor.create!(number: 1, building: building, tenant: person)
    unassigned_floor = Floor.create!(number: 2)
    column = ActiveScaffold::DataStructures::Column.new(:floors, Building)
    column.form_ui = [:select, {html_options: {multiple: true}}]
    @nested = ActiveScaffold::DataStructures::NestedInfo.get(
      Building,
      parent_scaffold: 'people', association: 'home', person_id: person.id
    )
    @nested_parent_record = person

    html = active_scaffold_input_select(
      column,
      {object: building, name: 'record[floors]', id: 'record_floors'},
      ui_options: column.form_ui_options
    )
    option_values = Nokogiri::HTML.fragment(html).css('option').pluck('value')

    assert_includes option_values, through_floor.id.to_s
    assert_not_includes option_values, unassigned_floor.id.to_s
  ensure
    Floor.delete_all
    Building.delete_all
    Person.delete_all
  end

  private

  def active_scaffold_config
    @active_scaffold_config ||= stub(cache_association_options: false)
  end

  def active_scaffold_config_for(klass)
    @active_scaffold_configs ||= {}
    @active_scaffold_configs[klass] ||= config_for(klass)
  end

  def nested?
    @nested.present?
  end

  attr_reader :nested, :nested_parent_record
end
