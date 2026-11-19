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

  def test_create_conditions_for_columns_supports_all_active_record_patterns_and_non_text_casting
    text_column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)

    assert_equal [['"model_stubs"."a" LIKE ?', 'foo%']],
                 ClassWithFinder.conditions_for_columns('foo', [text_column], :start)
    assert_equal [['"model_stubs"."a" LIKE ?', '%foo']],
                 ClassWithFinder.conditions_for_columns('foo', [text_column], :end)
    assert_equal [['"model_stubs"."a" LIKE ?', 'foo']],
                 ClassWithFinder.conditions_for_columns('foo', [text_column], :exact)

    numeric_column = ActiveScaffold::DataStructures::Column.new(:buildings_count, Person)
    assert_equal [['"people"."buildings_count" = ?', 12]],
                 ClassWithFinder.conditions_for_columns('12', [numeric_column])
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

  def test_mongoid_conditions_build_regex_selectors_for_each_text_search_mode
    query = Struct.new(:selector)
    model = Class.new
    model.define_singleton_method(:or) { |conditions| query.new({or: conditions}) }
    model.define_singleton_method(:and) { |conditions| query.new({and: conditions}) }
    config = stub(active_record?: false, mongoid?: true, model: model)
    finder = Class.new
    finder.define_singleton_method(:active_scaffold_config) { config }
    finder.extend ActiveScaffold::Finder::ClassMethods
    column = stub(name: :name, text?: true, search_sql: %w[name nickname], active_record?: false)

    {
      full: 'Alice',
      start: '^Alice',
      end: 'Alice$',
      exact: '^Alice$'
    }.each do |mode, expected_pattern|
      conditions = finder.conditions_for_columns('Alice', [column], mode)
      token_conditions = conditions.first.fetch(:and).first.fetch(:or)

      assert_equal %w[name nickname], token_conditions.flat_map(&:keys)
      assert_equal [expected_pattern, expected_pattern], token_conditions.flat_map(&:values).map(&:source)
    end
  end

  def test_mongoid_conditions_combine_multiple_tokens_with_and
    query = Struct.new(:selector)
    model = Class.new
    model.define_singleton_method(:or) { |conditions| query.new({or: conditions}) }
    model.define_singleton_method(:and) { |conditions| query.new({and: conditions}) }
    config = stub(active_record?: false, mongoid?: true, model: model)
    finder = Class.new
    finder.define_singleton_method(:active_scaffold_config) { config }
    finder.extend ActiveScaffold::Finder::ClassMethods
    column = stub(name: :name, text?: true, search_sql: [:name], active_record?: false)

    conditions = finder.conditions_for_columns(%w[Alice Bob], [column])

    patterns = conditions.first.fetch(:and).map { |condition| condition[:or].first['name'].source }
    assert_equal %w[Alice Bob], patterns
  end

  def test_like_operator_is_not_set_for_model_attribute
    model = Class.new(Person) do
      attribute :allow_after_hours, :boolean
    end

    column = ActiveScaffold::DataStructures::Column.new(:allow_after_hours, model)

    assert_nil column.like_operator
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

  def test_find_if_allowed_normalizes_symbol_security_options
    record = mock
    record.expects(:authorized_for?).with({crud_type: :read}).returns(true)
    relation = mock
    relation.expects(:find).with(7).returns(record)

    assert_same record, @klass.send(:find_if_allowed, 7, :read, relation)
  end

  def test_find_if_allowed_raises_for_an_unauthorized_record
    record = stub(authorized_for?: false)
    relation = stub(find: record, to_s: 'People')

    error = assert_raises(ActiveScaffold::RecordNotAllowed) do
      @klass.send(:find_if_allowed, 7, {crud_type: :update}, relation)
    end

    assert_includes error.message, 'id = 7'
  end

  def test_joins_for_finder_normalizes_custom_joins
    @klass.send(:active_scaffold_joins=, [:configured_join])

    @klass.stubs(:joins_for_collection).returns('INNER JOIN owners ON owners.id = owner_id')
    assert_equal ['INNER JOIN owners ON owners.id = owner_id', :configured_join],
                 @klass.send(:joins_for_finder)

    @klass.stubs(:joins_for_collection).returns([:people])
    assert_equal %i[people configured_join], @klass.send(:joins_for_finder)
  end

  def test_mongoid_finder_options_merge_references_and_preloads_as_includes
    @klass.active_scaffold_config.stubs(active_record?: false, mongoid?: true)
    @klass.send(:active_scaffold_references=, %i[owner comments])
    @klass.send(:active_scaffold_preload=, %i[comments tags])

    options = @klass.send(:finder_options)

    assert_equal %i[owner comments tags], options[:includes]
    assert_not options.key?(:joins)
    assert_not options.key?(:preload)
  end

  def test_append_to_query_applies_nested_conditions_and_relations
    base = ModelStub.where(nil)
    relation = ModelStub.where(a: 'from relation')

    query = @klass.send(
      :append_to_query,
      base,
      conditions: [[{id: 1}]], relations: [relation]
    )

    assert_equal({'id' => 1, 'a' => 'from relation'}, query.where_clause.to_h)
    assert_includes query.to_sql, 'from relation'
  end

  def test_method_sorted_page_beyond_collection_returns_empty_array
    column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    column.sort_by method: 'a'
    sorting = ActiveScaffold::DataStructures::Sorting.new({a: column}, ModelStub)
    sorting.add :a
    query = ModelStub.where(nil)
    query.stubs(count: 0, to_a: [])
    @klass.stubs(:filtered_query).returns(query)
    @klass.stubs(:append_to_query).returns(query)

    page = @klass.send(:find_page, sorting: sorting, per_page: 20, page: 2, pagination: true)

    assert_equal [], page.items
  end

  def test_find_page_adds_order_expressions_to_select_for_distinct_query
    sorting = sorting_by_function
    @klass.send(:active_scaffold_outer_joins) << :other_models
    ModelStub.connection.stubs(:needs_order_expressions_in_select?).returns(true)

    query = @klass.send(:find_page, sorting: sorting, pagination: false).items

    assert_equal ['"model_stubs".*', 'LOWER(model_stubs.a)'], query.select_values.map(&:to_s)
    assert_match(/SELECT DISTINCT "model_stubs"\.\*, LOWER\(model_stubs\.a\).*ORDER BY LOWER\(model_stubs\.a\) ASC/, query.to_sql)
  end

  def test_find_page_adds_order_expressions_when_filtered_query_is_distinct
    sorting = sorting_by_function
    @klass.stubs(:filtered_query).returns(ModelStub.where(nil).distinct)
    ModelStub.connection.stubs(:needs_order_expressions_in_select?).returns(true)

    query = @klass.send(:find_page, sorting: sorting, pagination: false).items

    assert_equal ['"model_stubs".*', 'LOWER(model_stubs.a)'], query.select_values.map(&:to_s)
    assert_match(/SELECT DISTINCT "model_stubs"\.\*, LOWER\(model_stubs\.a\).*ORDER BY LOWER\(model_stubs\.a\) ASC/, query.to_sql)
  end

  def test_find_page_preserves_select_when_adding_order_expressions
    sorting = sorting_by_function
    @klass.stubs(:filtered_query).returns(ModelStub.where(nil).distinct)
    ModelStub.connection.stubs(:needs_order_expressions_in_select?).returns(true)

    query = @klass.send(:find_page, sorting: sorting, select: 'model_stubs.id', pagination: false).items

    assert_equal ['model_stubs.id', 'LOWER(model_stubs.a)'], query.select_values.map(&:to_s)
  end

  def test_find_page_does_not_add_order_expressions_when_adapter_does_not_need_them
    sorting = sorting_by_function
    @klass.stubs(:filtered_query).returns(ModelStub.where(nil).distinct)

    query = @klass.send(:find_page, sorting: sorting, pagination: false).items

    assert_empty query.select_values
  end

  def test_append_to_query_makes_left_join_query_distinct
    query = @klass.send(:append_to_query, ModelStub.where(nil), left_joins: :other_models)

    assert_predicate query, :distinct_value
  end

  def test_append_to_query_does_not_make_belongs_to_left_join_query_distinct
    ModelStub.stubs(:reflect_on_association).with(:parent_model).returns(stub(macro: :belongs_to))

    query = @klass.send(:append_to_query, ModelStub.where(nil), left_joins: :parent_model)

    assert_not_predicate query, :distinct_value
  end

  def test_append_to_query_makes_has_one_left_join_query_distinct
    query = @klass.send(:append_to_query, ModelStub.where(nil), left_joins: :other_model)

    assert_predicate query, :distinct_value
  end

  def test_distinct_query_is_false_without_left_joins
    assert_not @klass.send(:distinct_query?, {})
  end

  def test_distinct_query_is_true_for_unknown_association
    assert @klass.send(:distinct_query?, left_joins: :missing_association)
  end

  def test_distinct_query_is_true_for_nested_associations
    assert @klass.send(:distinct_query?, left_outer_joins: {parent_model: :other_models})
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

  def test_conditions_for_numeric_column
    column = ActiveScaffold::DataStructures::Column.new('buildings_count', Person)

    assert_equal ['"people"."buildings_count" = ?', 12],
                 ClassWithFinder.condition_for_column(column, '12', :full, {})
    assert_equal ['("people"."buildings_count" BETWEEN ? AND ?)', 2, 4],
                 ClassWithFinder.condition_for_column(column, {opt: 'BETWEEN', from: '2', to: '4'}, :full, {})
    assert_equal ['"people"."buildings_count" >= ?', 2],
                 ClassWithFinder.condition_for_column(column, {opt: '>=', from: '2'}, :full, {})
    assert_equal ['"people"."buildings_count" is null', []],
                 ClassWithFinder.condition_for_column(column, {opt: 'null'}, :full, {})
    assert_nil ClassWithFinder.condition_for_column(column, {opt: 'BETWEEN', from: ''}, :full, {})
    assert_nil ClassWithFinder.condition_for_column(column, {opt: 'LIKE', from: '2'}, :full, {})
  end

  def test_conditions_for_range_column
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)

    assert_equal ['"people"."first_name" LIKE ?', '%Alice%'],
                 ClassWithFinder.condition_for_column(column, {opt: '%?%', from: 'Alice'}, :full, {})
    assert_equal ['"people"."first_name" NOT LIKE ?', 'Alice%'],
                 ClassWithFinder.condition_for_column(column, {opt: 'not_?%', from: 'Alice'}, :full, {})
    assert_equal ['("people"."first_name" BETWEEN ? AND ?)', 'Alice', 'Bob'],
                 ClassWithFinder.condition_for_column(column, {opt: 'BETWEEN', from: 'Alice', to: 'Bob'}, :full, {})
    assert_equal ['"people"."first_name" in (?)', %w[Alice Bob]],
                 ClassWithFinder.condition_for_column(column, {opt: '=', from: ['Alice', '', 'Bob']}, :full, {})
    assert_equal ['"people"."first_name" is not null', []],
                 ClassWithFinder.condition_for_column(column, {opt: 'not_null'}, :full, {})
  end

  def test_conditions_for_select_and_record_select_columns
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    column.search_ui = :select

    assert_equal ['"people"."first_name" in (?)', %w[Alice Bob]],
                 ClassWithFinder.condition_for_column(column, ['Alice', '', 'Bob'], :full, {})
    assert_nil ClassWithFinder.condition_for_column(column, [], :full, {})
    assert_equal ['%<search_sql>s IN (?)', %w[1 2]],
                 ClassWithFinder.condition_for_record_select_type(column, ['1', '', '2'])
    assert_equal ['%<search_sql>s = ?', '1'],
                 ClassWithFinder.condition_for_record_select_type(column, '1')
  end

  def test_condition_for_column_uses_custom_column_method_with_session
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    session = {account_id: 7}
    ClassWithFinder.define_singleton_method(:condition_for_first_name_column) do |received_column, value, pattern, received_session|
      [received_column.name, value, pattern, received_session]
    end

    assert_equal [:first_name, 'Alice', '%?%', session],
                 ClassWithFinder.condition_for_column(column, 'Alice', :full, session)
  ensure
    ClassWithFinder.singleton_class.remove_method(:condition_for_first_name_column)
  end

  def test_condition_for_column_uses_search_ui_method_and_search_sql_proc
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    ClassWithFinder.define_singleton_method(:condition_for_custom_type) do |received_column, value, pattern|
      ['%<search_sql>s = ?', "#{received_column.name}:#{pattern}:#{value}"]
    end
    column.search_ui = :custom

    assert_equal ['"people"."first_name" = ?', 'first_name:%?%:Alice'],
                 ClassWithFinder.condition_for_column(column, 'Alice', :full, {})

    column.search_ui = nil
    column.search_sql = proc { |value| [Person.where(first_name: value)] }
    condition = ClassWithFinder.condition_for_column(column, 'Alice', :full, {})
    assert_kind_of ActiveRecord::Relation, condition
    assert_equal({'first_name' => 'Alice'}, condition.where_clause.to_h)
  ensure
    ClassWithFinder.singleton_class.remove_method(:condition_for_custom_type)
  end

  def test_condition_value_for_integer
    column = ActiveScaffold::DataStructures::Column.new('buildings_count', Person)
    column.search_ui = :integer

    assert_equal 12, ClassWithFinder.condition_value_for_numeric(column, '12')
    assert_equal 1, ClassWithFinder.condition_value_for_numeric(column, true)
    assert_equal 0, ClassWithFinder.condition_value_for_numeric(column, false)
  end

  def test_condition_values_for_float_decimal_and_untyped_numeric_columns
    column = ActiveScaffold::DataStructures::Column.new('buildings_count', Person)

    column.search_ui = :float
    assert_equal 12.5, ClassWithFinder.condition_value_for_numeric(column, '12.5')

    column.search_ui = :decimal
    assert_equal BigDecimal('12.5'), ClassWithFinder.condition_value_for_numeric(column, '12.5')

    column.search_ui = :custom
    assert_equal '12.5', ClassWithFinder.condition_value_for_numeric(column, '12.5')
  end

  def test_condition_for_non_text_single_value
    column = ActiveScaffold::DataStructures::Column.new('buildings_count', Person)

    assert_equal ['%<search_sql>s = ?', 2], ClassWithFinder.condition_for_single_value(column, '2')
  end

  def test_condition_for_column_adds_column_context_to_errors
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    column.search_sql = proc { raise ArgumentError, 'invalid search' }
    ActiveScaffold.expects(:log_exception).with(instance_of(ArgumentError), includes('first_name'))

    error = assert_raises(ArgumentError) do
      ClassWithFinder.condition_for_column(column, 'Alice', :full, {})
    end

    assert_includes error.message, 'invalid search -- on the ActiveScaffold column :first_name'
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
