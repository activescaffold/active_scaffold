# frozen_string_literal: true

require 'test_helper'
require 'class_with_finder'

class FinderTest < ActiveSupport::TestCase
  def setup
    @klass = ClassWithFinder.new
    @klass.active_scaffold_config.stubs(model: ModelStub)
  end

  def test_create_conditions_for_columns
    columns = [
      ActiveScaffold::DataStructures::Column.new(:a, ModelStub),
      ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    ]
    tokens = %w[foo bar]

    expected_conditions = [
      ['"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?', '%foo%', '%foo%'],
      ['"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?', '%bar%', '%bar%']
    ]
    assert_equal expected_conditions, ClassWithFinder.conditions_for_columns(tokens, columns)

    expected_conditions = [
      '"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?',
      '%foo%', '%foo%'
    ]
    assert_equal [expected_conditions], ClassWithFinder.conditions_for_columns('foo', columns)

    assert_nil ClassWithFinder.conditions_for_columns('foo', [])
  end

  def test_create_conditions_for_columns_uses_like_for_collated_postgresql_column
    columns_hash = ModelStub.columns_hash.merge('b' => ColumnMock.new('b', '', 'varchar(255)', true, collation: 'case_insensitive'))
    ModelStub.stubs(columns_hash: columns_hash)
    ModelStub.connection.stubs(adapter_name: 'PostgreSQL')
    columns = [
      ActiveScaffold::DataStructures::Column.new(:a, ModelStub),
      ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    ]

    expected_conditions = [
      '"model_stubs"."a" ILIKE ? OR "model_stubs"."b" LIKE ?',
      '%foo%', '%foo%'
    ]
    assert_nil columns.first.like_operator
    assert_equal 'LIKE', columns.last.like_operator
    assert_equal [expected_conditions], ClassWithFinder.conditions_for_columns('foo', columns)
  end

  def test_condition_for_column_uses_configured_like_operator
    column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    column.like_operator = 'ILIKE'

    assert_equal ['"model_stubs"."a" ILIKE ?', '%foo%'], ClassWithFinder.condition_for_column(column, 'foo', :full, {})
  end

  def test_method_sorting
    column = ActiveScaffold::DataStructures::Column.new('a', ModelStub)
    column.sort_by method: proc { a }

    collection = [ModelStub.new(a: 'x'), ModelStub.new(a: 'b'), ModelStub.new(a: 'z'), ModelStub.new(a: 'a')]
    assert_equal collection.map(&:a).sort, @klass.send(:sort_collection_by_column, collection, column, 'asc').map(&:a)
    assert_equal collection.map(&:a).sort.reverse, @klass.send(:sort_collection_by_column, collection, column, 'desc').map(&:a)

    collection = [ModelStub.new(a: 'a'), ModelStub.new(a: nil), ModelStub.new(a: 'b')]
    result = @klass.send(:sort_collection_by_column, collection, column, 'asc').map(&:a)
    assert_equal [nil, 'a', 'b'], result

    column.sort_by method: 'a'
    collection = [ModelStub.new(a: 'c'), ModelStub.new(a: 'a'), ModelStub.new(a: 'b')]
    assert_equal collection.map(&:a).sort, @klass.send(:sort_collection_by_column, collection, column, 'asc').map(&:a)
  end

  def test_finder_options_add_order_expressions_to_select_for_distinct_query
    sorting = sorting_by_function
    @klass.send(:active_scaffold_outer_joins) << :other_models
    ModelStub.connection.stubs(:needs_order_expressions_in_select?).returns(true)

    options = @klass.send(:finder_options, sorting: sorting)

    assert_equal ['"model_stubs".*', 'LOWER(model_stubs.a)'], options[:select].map(&:to_s)
    query = @klass.send(:append_to_query, ModelStub.where(nil), options)
    assert_match(/SELECT DISTINCT "model_stubs"\.\*, LOWER\(model_stubs\.a\).*ORDER BY LOWER\(model_stubs\.a\) ASC/, query.to_sql)
  end

  def test_finder_options_preserve_select_when_adding_order_expressions
    sorting = sorting_by_function
    @klass.send(:active_scaffold_outer_joins) << :other_models
    ModelStub.connection.stubs(:needs_order_expressions_in_select?).returns(true)

    options = @klass.send(:finder_options, sorting: sorting, select: 'model_stubs.id')

    assert_equal ['model_stubs.id', 'LOWER(model_stubs.a)'], options[:select].map(&:to_s)
  end

  def test_finder_options_do_not_add_order_expressions_when_adapter_does_not_need_them
    sorting = sorting_by_function
    @klass.send(:active_scaffold_outer_joins) << :other_models

    options = @klass.send(:finder_options, sorting: sorting)

    assert_nil options[:select]
  end

  def test_append_to_query_makes_left_join_query_distinct
    query = @klass.send(:append_to_query, ModelStub.where(nil), left_joins: :other_models)

    assert_predicate query, :distinct_value
  end

  def test_count_with_group
    @klass.expects(:custom_finder_options).returns(group: :a)
    relation_class.any_instance.expects(:count).returns('foo' => 5, 'bar' => 4)
    relation_class.any_instance.expects(:limit).with(20).returns(ModelStub.where(nil))
    relation_class.any_instance.expects(:offset).with(20).returns(ModelStub.where(nil))
    page = @klass.send :find_page, per_page: 20, page: 2, pagination: true
    page.items

    assert_kind_of Integer, page.pager.count
    assert_equal 2, page.pager.count
    assert_equal 1, page.pager.number_of_pages
  end

  def test_first_page_does_not_count_when_it_is_not_full
    records = [ModelStub.new(a: 'a'), ModelStub.new(a: 'b')]
    @klass.expects(:load_page_for_delayed_count).with(kind_of(relation_class), 20).returns(records)
    relation_class.any_instance.expects(:count).never

    page = @klass.send :find_page, per_page: 20, pagination: true

    assert_equal records, page.items
    assert_equal 2, page.pager.count
    assert_equal 1, page.pager.number_of_pages
  end

  def test_first_page_counts_when_it_is_full
    records = Array.new(20) { ModelStub.new }
    @klass.expects(:load_page_for_delayed_count).with(kind_of(relation_class), 20).returns(records)
    relation_class.any_instance.expects(:count).returns(57)

    page = @klass.send :find_page, per_page: 20, pagination: true

    assert_equal records, page.items
    assert_equal 57, page.pager.count
    assert_equal 3, page.pager.number_of_pages
  end

  def test_disabled_pagination
    relation_class.any_instance.expects(:count).never
    relation_class.any_instance.expects(:limit).never
    relation_class.any_instance.expects(:offset).never
    ModelStub.expects(:count).never
    page = @klass.send :find_page, per_page: 20, pagination: false
    page.items
  end

  def test_infinite_pagination
    ModelStub.expects(:count).never
    @klass.send :find_page, pagination: :infinite
  end

  def test_condition_for_column
    column = ActiveScaffold::DataStructures::Column.new('adult', Person)
    assert_equal ['"people"."adult" = ?', false], ClassWithFinder.condition_for_column(column, '0', :full, {})
  end

  def test_condition_for_polymorphic_column
    column = ActiveScaffold::DataStructures::Column.new('addressable', Address)
    column.search_sql = [{subquery: [Building, 'name']}]
    condition = ClassWithFinder.condition_for_column(column, 'test search', :full, {})
    assert_equal Building.where(['name LIKE ?', '%test search%']).select(:id).to_sql, condition[1].to_sql
    assert_equal '"addresses"."addressable_id" IN (?) AND "addresses"."addressable_type" = ?', condition[0]
    assert_equal ['Building'], condition[2..]
  end

  def test_condition_for_polymorphic_column_with_relation
    column = ActiveScaffold::DataStructures::Column.new('contactable', Contact)
    column.search_sql = [{subquery: [Person.joins(:buildings), 'first_name', 'last_name']}]
    condition = ClassWithFinder.condition_for_column(column, 'test search', :full, {})
    assert_equal Person.joins(:buildings).where(['first_name LIKE ? OR last_name LIKE ?', '%test search%', '%test search%']).select(:id).to_sql, condition[1].to_sql
    assert_equal '"contacts"."contactable_id" IN (?) AND "contacts"."contactable_type" = ?', condition[0]
    assert_equal ['Person'], condition[2..]
  end

  def test_subquery_condition_for_association_with_condition
    column = ActiveScaffold::DataStructures::Column.new('owner', Building)
    column.search_sql = [{subquery: [Person, 'first_name', 'last_name'], conditions: ['floor_count > 0']}]
    column.search_ui = :text
    condition = ClassWithFinder.condition_for_column(column, 'test search', :full, {})
    assert_equal Person.where(['first_name LIKE ? OR last_name LIKE ?', '%test search%', '%test search%']).select(:id).to_sql, condition[1].to_sql
    assert_equal '"buildings"."owner_id" IN (?) AND floor_count > 0', condition[0]
    assert_equal [], condition[2..]
  end

  def test_subquery_condition_for_association_with_conditions
    column = ActiveScaffold::DataStructures::Column.new('owner', Building)
    column.search_sql = [{subquery: [Person, 'first_name', 'last_name'], conditions: ['floor_count > 0 AND name != ?', '']}]
    column.search_ui = :text
    condition = ClassWithFinder.condition_for_column(column, 'test search', :full, {})
    assert_equal Person.where(['first_name LIKE ? OR last_name LIKE ?', '%test search%', '%test search%']).select(:id).to_sql, condition[1].to_sql
    assert_equal '"buildings"."owner_id" IN (?) AND floor_count > 0 AND name != ?', condition[0]
    assert_equal [''], condition[2..]
  end

  private

  def sorting_by_function
    column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    column.sort_by sql: Arel.sql('LOWER(model_stubs.a)')
    sorting = ActiveScaffold::DataStructures::Sorting.new({a: column}, ModelStub)
    sorting.add :a
    sorting
  end

  def relation_class
    @klass.active_scaffold_config.model.send(:relation).class
  end
end
