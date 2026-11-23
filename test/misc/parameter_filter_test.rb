# frozen_string_literal: true

require 'test_helper'

class ParameterFilterTest < ActiveSupport::TestCase
  setup do
    @config = ActiveScaffold::Config::Core.new(:person)
    @controller = PeopleController.new
    @controller.stubs(:active_scaffold_config).returns(@config)
  end

  test 'nil allowlist preserves filters on database columns' do
    assert_equal [{last_name: 'Secret'}], conditions(last_name: 'Secret')
  end

  test 'empty allowlist disables parameter filtering' do
    @config.conditions_from_params_allowed_columns = []
    @controller.expects(:params).never
    @config.expects(:conditions_from_params_excluded_columns).never

    assert_equal [{}], conditions(first_name: 'Visible', last_name: 'Secret', 'created_at!' => '..2026-01-01')
  end

  test 'allowlist accepts both string and symbol names' do
    @config.conditions_from_params_allowed_columns = [:first_name, 'adult']

    assert_equal [{first_name: 'Visible', adult: true}], conditions(first_name: 'Visible', adult: 'true', last_name: 'Secret')
  end

  test 'reject list applies with the default unrestricted allowlist' do
    @config.conditions_from_params_excluded_columns = ['last_name']

    assert_equal [{first_name: 'Visible'}], conditions(first_name: 'Visible', last_name: 'Secret')
  end

  test 'exclusions win over explicit allowances and cover negated ranges and arrays' do
    @config.conditions_from_params_allowed_columns = %i[first_name last_name created_at]
    @config.conditions_from_params_excluded_columns = [:last_name, 'created_at']

    assert_equal [{first_name: 'Visible'}], conditions(first_name: 'Visible', 'last_name!' => ['Secret'], created_at: '..2026-01-01')
  end

  test 'allowed filters retain range array and negation behavior' do
    @config.conditions_from_params_allowed_columns = %i[first_name created_at adult]

    result = conditions(first_name: %w[A B], created_at: '2026-01-01..2026-12-31', 'adult!' => 'true')

    assert_equal %w[A B], result.first[:first_name]
    assert_kind_of Range, result.first[:created_at]
    assert_equal 2, result.length
    assert_instance_of Arel::Nodes::NotEqual, result.last
    assert_equal 'adult', result.last.left.name
  end

  private

  def conditions(values)
    @controller.params = ActionController::Parameters.new(values)
    @controller.send(:conditions_from_params)
  end
end
