# frozen_string_literal: true

require 'test_helper'

class FieldSearchActionTest < ActionController::TestCase
  tests ContactsController

  test 'parses the grouped field and calculation function' do
    @controller.active_scaffold_config.field_search.stubs(:group_options).returns([['Month', 'birthday#year_month']])
    @controller.stubs(:search_params).returns('active_scaffold_group' => 'birthday#year_month')

    assert @controller.send(:grouped_search?)
    assert_equal 'birthday', @controller.send(:search_group_name)
    assert_equal 'year_month', @controller.send(:search_group_function)
    assert_equal :birthday, @controller.send(:search_group_column).name
  end

  test 'builds supported grouped date calculations' do
    group_sql = ['contacts.birthday']

    assert_match(/extract\(year FROM contacts\.birthday\)/i,
                 @controller.send(:calculation_for_group_by, group_sql, 'year').to_sql)
    assert_match(/extract\(year FROM contacts\.birthday\).*100.*extract\(month FROM contacts\.birthday\)/i,
                 @controller.send(:calculation_for_group_by, group_sql, 'year_month').to_sql)
    assert_match(/extract\(year FROM contacts\.birthday\).*10.*extract\(quarter FROM contacts\.birthday\)/i,
                 @controller.send(:calculation_for_group_by, group_sql, 'year_quarter').to_sql)
  end

  test 'rejects unsupported grouped calculations' do
    error = assert_raises(ArgumentError) do
      @controller.send(:calculation_for_group_by, ['contacts.birthday'], 'week')
    end

    assert_includes error.message, 'week unsupported'
  end

  test 'keeps relations separate from ordinary search conditions' do
    relation_column = @controller.active_scaffold_config.columns[:first_name]
    condition_column = @controller.active_scaffold_config.columns[:last_name]
    relation = Contact.where(first_name: 'Alice')
    condition = ['contacts.last_name = ?', 'Example']
    relations = []
    conditions = []
    @controller.stubs(:active_scaffold_relations).returns(relations)
    @controller.stubs(:active_scaffold_conditions).returns(conditions)
    @controller.expects(:setup_joins_for_filtered_columns).with([condition_column])
    @controller.expects(:setup_human_conditions).with([relation_column, condition_column])

    @controller.send(:process_search_conditions, [[relation_column, relation], [condition_column, condition]])

    assert_equal [relation], relations
    assert_equal [condition], conditions
  end

  test 'marks a grouped search as filtered even without search conditions' do
    @controller.stubs(:grouped_search?).returns(true)
    @controller.send(:setup_human_conditions, [])

    assert_equal true, @controller.instance_variable_get(:@filtered)
  end

  test 'builds finder options for a grouped calculation' do
    group_column = stub(group_by: nil)
    calculated_select = Arel.sql('COUNT(*)').as('total')
    group_expression = @controller.send(:calculation_for_group_by, ['contacts.birthday'], 'year')
    sorting = [Arel.sql('birthday ASC')]
    @controller.stubs(:search_group_column).returns(group_column)
    @controller.stubs(:search_group_name).returns('birthday')
    @controller.stubs(:search_group_function).returns('year')
    @controller.stubs(:grouped_search_select).returns([calculated_select])
    @controller.expects(:calculation_for_group_by).with(['birthday'], 'year').returns(group_expression)
    @controller.expects(:grouped_sorting).with(group_expression.to_sql).returns(sorting)

    options = @controller.send(:grouped_search_finder_options)

    assert_equal group_expression.to_sql, options[:group]
    assert_equal 2, options[:select].size
    assert_equal 'birthday', options[:select].last.right
    assert_same sorting, options[:reorder]
  end

  test 'builds finder options for a grouped column without a function' do
    group_column = stub(group_by: %w[contacts.year contacts.month])
    @controller.stubs(:search_group_column).returns(group_column)
    @controller.stubs(:search_group_name).returns('birthday')
    @controller.stubs(:search_group_function).returns(nil)
    @controller.stubs(:grouped_search_select).returns([])
    @controller.expects(:calculation_for_group_by)
      .with(group_column.group_by, nil).returns(%w[quoted_year quoted_month])
    @controller.expects(:quoted_select_columns)
      .with([['contacts.year', 'birthday_0'], ['contacts.month', 'birthday_1']])
      .returns(%w[selected_year selected_month])
    @controller.expects(:grouped_sorting).with.returns(nil)

    options = @controller.send(:grouped_search_finder_options)

    assert_equal %w[quoted_year quoted_month], options[:group]
    assert_equal %w[selected_year selected_month], options[:select]
    assert_nil options[:reorder]
  end

  test 'builds calculations for grouped list columns' do
    group_column = stub(name: :birthday)
    calculated_column = stub(name: :id, calculate: :count, grouped_select: 'contacts.id')
    @controller.stubs(:list_columns).returns([group_column, calculated_column])

    calculations = @controller.send(:grouped_columns_calculations)

    assert_equal [:id], calculations.keys
    assert_match(/count\('contacts\.id'\)/i, calculations[:id].to_sql)
  end
end
