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

  def test_method_sorting
    column = ActiveScaffold::DataStructures::Column.new('a', ModelStub)
    column.sort_by method: proc { self }

    collection = [16_000, 2853, 98_765, 6188, 4]
    assert_equal collection.sort, @klass.send(:sort_collection_by_column, collection, column, 'asc')
    assert_equal collection.sort.reverse, @klass.send(:sort_collection_by_column, collection, column, 'desc')

    collection = ['a', nil, 'b']
    result = @klass.send(:sort_collection_by_column, collection, column, 'asc')
    assert_equal [nil, 'a', 'b'], result

    column.sort_by method: 'self'
    collection = [3, 1, 2]
    assert_equal collection.sort, @klass.send(:sort_collection_by_column, collection, column, 'asc')
  end

  def test_count_with_group
    @klass.expects(:custom_finder_options).returns(group: :a)
    relation_class.any_instance.expects(:count).returns('foo' => 5, 'bar' => 4)
    relation_class.any_instance.expects(:limit).with(20).returns(ModelStub.where(nil))
    relation_class.any_instance.expects(:offset).with(0).returns(ModelStub.where(nil))
    page = @klass.send :find_page, per_page: 20, pagination: true
    page.items

    assert_kind_of Integer, page.pager.count
    assert_equal 2, page.pager.count
    assert_equal 1, page.pager.number_of_pages
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

  def relation_class
    @klass.active_scaffold_config.model.send(:relation).class
  end
end
