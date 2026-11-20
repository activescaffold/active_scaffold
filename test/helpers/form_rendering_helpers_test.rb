# frozen_string_literal: true

require 'test_helper'

class NumericalConstraintsModel < ActiveScaffold::Tableless
  column :odd_number, :integer
  column :even_number, :integer
  column :decimal_number, 'decimal(8, 3)'
  column :equal_number, :integer

  validates :odd_number, numericality: {only_integer: true, odd: true, greater_than_or_equal_to: 0}
  validates :even_number, numericality: {only_integer: true, even: true, greater_than_or_equal_to: 1}
  validates :decimal_number, numericality: true
  validates :equal_number, numericality: {equal_to: 7}
end

class FormRenderingHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def test_clear_form_column_if_clears_scalar_select_and_checkboxes_values
    record = ModelStub.new(a: 'text', b: 'selected', c: %w[first second])
    columns = %i[a b c].map { |name| ActiveScaffold::DataStructures::Column.new(name, ModelStub) }
    columns[1].form_ui = :select
    columns[2].form_ui = :checkboxes
    columns.each { |column| column.clear_form_column_if = true }

    inputs = columns.map do |column|
      html = render_column(column, record, :field)
      Nokogiri::HTML.fragment(html).at_css('input[type="hidden"]')
    end

    assert_equal 'record[a]', inputs[0]['name']
    assert_equal 'record[b]', inputs[1]['name']
    assert_equal 'record[c][]', inputs[2]['name']
    inputs.each { |input| assert_empty input['value'].to_s }
  end

  def test_hide_form_column_if_hides_scalar_select_and_checkboxes_without_submitting_values
    record = ModelStub.new(a: 'text', b: 'selected', c: %w[first second])
    record.define_singleton_method(:hide_checkboxes?) { true }
    columns = %i[a b c].map { |name| ActiveScaffold::DataStructures::Column.new(name, ModelStub) }
    columns[0].hide_form_column_if = true
    columns[1].form_ui = :select
    columns[1].hide_form_column_if = lambda do |received_record, received_column, scope|
      received_record == record && received_column == columns[1] && scope == '[children][0]'
    end
    columns[2].form_ui = :checkboxes
    columns[2].hide_form_column_if = :hide_checkboxes?

    inputs = columns.map do |column|
      html = render_column(column, record, :field, '[children][0]')
      Nokogiri::HTML.fragment(html).at_css('input[type="hidden"]')
    end

    inputs.each_with_index do |input, index|
      assert_nil input['name']
      assert_includes input['class'], "#{columns[index].name}-input"
    end
  end

  def test_hidden_form_ui_for_singular_association_submits_associated_id
    category = Category.new(id: 9, name: 'Hidden category')
    record = Task.new(category: category)
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    column.form_ui = :hidden

    html = render_column(column, record, column_renders_as(column))
    input = Nokogiri::HTML.fragment(html).at_css('input[type="hidden"]')

    assert_equal :hidden, column_renders_as(column)
    assert_equal 'record[category]', input['name']
    assert_equal '9', input['value']
  end

  def test_hidden_form_ui_for_collection_association_submits_each_associated_id
    roles = [Role.new(id: 4, name: 'Editor'), Role.new(id: 7, name: 'Reviewer')]
    record = stub(roles: roles)
    column = ActiveScaffold::DataStructures::Column.new(:roles, Person)
    column.form_ui = :hidden

    html = render_column(column, record, column_renders_as(column))
    inputs = Nokogiri::HTML.fragment(html).css('input[type="hidden"]')

    assert_equal :hidden, column_renders_as(column)
    assert_equal ['record[roles][]'], inputs.pluck('name').uniq
    assert_equal %w[4 7], inputs.pluck('value')
  end

  def test_odd_and_even_validations_set_step_and_adjust_minimum
    odd_column = ActiveScaffold::DataStructures::Column.new(:odd_number, NumericalConstraintsModel)
    even_column = ActiveScaffold::DataStructures::Column.new(:even_number, NumericalConstraintsModel)

    assert_equal({min: 1, max: nil, step: 2}, column_numerical_constraints(odd_column, {}))
    assert_equal({min: 2, max: nil, step: 2}, column_numerical_constraints(even_column, {}))
  end

  def test_decimal_column_uses_scale_for_step
    column = ActiveScaffold::DataStructures::Column.new(:decimal_number, NumericalConstraintsModel)
    column.stubs(:column).returns(stub(scale: 3))

    assert_equal({min: nil, max: nil, step: '0.001'}, column_numerical_constraints(column, {}))
  end

  def test_equal_to_validation_sets_equal_minimum_and_maximum
    column = ActiveScaffold::DataStructures::Column.new(:equal_number, NumericalConstraintsModel)

    assert_equal({min: 7, max: 7}, column_numerical_constraints(column, {}))
  end
end
