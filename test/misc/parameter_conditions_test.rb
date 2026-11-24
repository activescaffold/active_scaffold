# frozen_string_literal: true

require 'test_helper'

class ParameterConditionsTest < ActiveSupport::TestCase
  setup do
    @config = ActiveScaffold::Config::Core.new(:person)
    @config.conditions_from_params_allowed_columns = %i[first_name buildings_count]
    @controller = PeopleController.new
    @controller.stubs(active_scaffold_config: @config,
                      active_scaffold_constraints: {}, nested?: false)
  end

  test 'builds conditions only for configured column parameters' do
    conditions = conditions_from(first_name: 'Alice', unknown: 'ignored', page: '2')

    assert_equal [{first_name: 'Alice'}], conditions
  end

  test 'casts arrays and removes blank non-string values' do
    conditions = conditions_from(buildings_count: ['1', '', '3'])

    assert_equal [{buildings_count: [1, nil, 3]}], conditions
  end

  test 'casts blank values to the column default when appropriate' do
    assert_equal [{buildings_count: 0}], conditions_from(buildings_count: '')
  end

  test 'casts supported ranges' do
    conditions = conditions_from(buildings_count: '2..4')

    assert_equal [{buildings_count: (2..4)}], conditions
  end

  test 'does not interpret unsupported or ambiguous values as ranges' do
    assert_equal [{first_name: 'Alice..Bob'}], conditions_from(first_name: 'Alice..Bob')
    assert_equal [{buildings_count: 1}], conditions_from(buildings_count: '1..2..3')
  end

  test 'builds exclusion nodes for scalar array and range values' do
    scalar = conditions_from('first_name!' => 'Alice').second
    array = conditions_from('buildings_count!' => %w[1 3]).second
    range = conditions_from('buildings_count!' => '2..4').second

    assert_equal '"people"."first_name" != \'Alice\'', scalar.to_sql
    assert_equal '"people"."buildings_count" NOT IN (1, 3)', array.to_sql
    assert_equal '("people"."buildings_count" < 2 OR "people"."buildings_count" > 4)', range.to_sql
  end

  test 'ignores constrained and nested parent columns' do
    @controller.stubs(active_scaffold_constraints: {first_name: 'Constrained'})
    assert_equal [{}], conditions_from(first_name: 'Alice')

    @controller = PeopleController.new
    @controller.stubs(active_scaffold_config: @config,
                      active_scaffold_constraints: {}, nested?: true, nested: stub(param_name: :first_name))
    assert_equal [{}], conditions_from(first_name: 'Alice')
  end

  private

  def conditions_from(parameters)
    @controller.stubs(params: ActionController::Parameters.new(parameters))
    @controller.remove_instance_variable(:@conditions_from_params) if @controller.instance_variable_defined?(:@conditions_from_params)
    @controller.send(:conditions_from_params)
  end
end
