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

  test 'unconfigured implicit filters warn once across controller instances' do
    controller_class = Class.new(PeopleController)
    @controller = controller_class.new
    @controller.stubs(:active_scaffold_config).returns(@config)
    ActiveScaffold.deprecator.expects(:warn).with do |message|
      message.include?('hidden or unauthorized') && message.include?('4.5') &&
        message.include?('conditions_from_params_allowed_columns = nil') &&
        message.include?('conditions_from_params_excluded_columns = []')
    end.once

    assert_equal [{first_name: 'First'}], conditions(first_name: 'First')
    @controller = controller_class.new
    @controller.stubs(:active_scaffold_config).returns(@config)
    assert_equal [{first_name: 'Second'}], conditions(first_name: 'Second')
  end

  test 'different controllers each warn when implicit filters are used' do
    ActiveScaffold.deprecator.expects(:warn).twice

    2.times do
      @controller = Class.new(PeopleController).new
      @controller.stubs(:active_scaffold_config).returns(@config)
      conditions(first_name: 'First')
    end
  end

  test 'ordinary listing parameters and unknown columns do not warn' do
    ActiveScaffold.deprecator.expects(:warn).never

    assert_equal [{}], conditions(page: '2', sort: 'first_name', unknown: 'ignored')
  end

  test 'constraints that skip implicit filters do not warn' do
    @controller.stubs(:active_scaffold_constraints).returns(first_name: 'Constrained')
    ActiveScaffold.deprecator.expects(:warn).never

    assert_equal [{}], conditions(first_name: 'Ignored')
  end

  test 'explicit empty exclusions retain legacy filtering without a warning' do
    @config.conditions_from_params_excluded_columns = []
    ActiveScaffold.deprecator.expects(:warn).never

    assert_equal [{last_name: 'Secret'}], conditions(last_name: 'Secret')
  end

  test 'explicit allowlists do not warn' do
    @config.conditions_from_params_allowed_columns = [:first_name]
    ActiveScaffold.deprecator.expects(:warn).never

    assert_equal [{first_name: 'Visible'}], conditions(first_name: 'Visible')
  end

  test 'explicit exclusions do not warn' do
    @config.conditions_from_params_excluded_columns = [:last_name]
    ActiveScaffold.deprecator.expects(:warn).never

    assert_equal [{first_name: 'Visible'}], conditions(first_name: 'Visible', last_name: 'Hidden')
  end

  private

  def conditions(values)
    @controller.params = ActionController::Parameters.new(values)
    @controller.send(:conditions_from_params)
  end
end
