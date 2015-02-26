require 'test_helper'

class ClassWithFinder
  include ActiveScaffold::Finder
  def conditions_for_collection; end

  def conditions_from_params; end

  def conditions_from_constraints; end

  def joins_for_collection; end

  def custom_finder_options
    {}
  end

  def beginning_of_chain
    active_scaffold_config.model
  end

  def conditional_get_support?; end

  def params; {}; end
end

class FinderTest < MiniTest::Test
  def setup
    @klass = ClassWithFinder.new
    @klass.stubs(:active_scaffold_config).returns(mock { stubs(:model).returns(ModelStub) })
    @klass.stubs(:active_scaffold_session_storage).returns({})
  end

  def test_create_conditions_for_columns
    columns = [
      ActiveScaffold::DataStructures::Column.new(:a, ModelStub),
      ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    ]
    tokens = %w(foo bar)

    expected_conditions = [
      ['"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?', '%foo%', '%foo%'],
      ['"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?', '%bar%', '%bar%']
    ]
    assert_equal expected_conditions, ClassWithFinder.create_conditions_for_columns(tokens, columns)

    expected_conditions = [
      '"model_stubs"."a" LIKE ? OR "model_stubs"."b" LIKE ?',
      '%foo%', '%foo%'
    ]
    assert_equal [expected_conditions], ClassWithFinder.create_conditions_for_columns('foo', columns)

    assert_equal nil, ClassWithFinder.create_conditions_for_columns('foo', [])
  end

  def test_method_sorting
    column = ActiveScaffold::DataStructures::Column.new('a', ModelStub)
    column.sort_by :method => proc { self }

    collection = [16_000, 2853, 98_765, 6188, 4]
    assert_equal collection.sort, @klass.send(:sort_collection_by_column, collection, column, 'asc')
    assert_equal collection.sort.reverse, @klass.send(:sort_collection_by_column, collection, column, 'desc')

    collection = ['a', nil, 'b']
    result = @klass.send(:sort_collection_by_column, collection, column, 'asc')
    assert_equal [nil, 'a', 'b'], result

    column.sort_by :method => 'self'
    collection = [3, 1, 2]
    assert_equal collection.sort, @klass.send(:sort_collection_by_column, collection, column, 'asc')
  end

  def test_count_with_group
    @klass.expects(:custom_finder_options).returns(:group => :a)
    relation_class.any_instance.expects(:count).returns('foo' => 5, 'bar' => 4)
    relation_class.any_instance.expects(:limit).with(20).returns(ModelStub.where(nil))
    relation_class.any_instance.expects(:offset).with(0).returns(ModelStub.where(nil))
    page = @klass.send :find_page, :per_page => 20, :pagination => true
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
    page = @klass.send :find_page, :per_page => 20, :pagination => false
    page.items
  end

  def test_infinite_pagination
    ModelStub.expects(:count).never
    @klass.send :find_page, :pagination => :infinite
  end

  def test_condition_for_column
    column = ActiveScaffold::DataStructures::Column.new('adult', Person)
    assert_equal ['"people"."adult" = ?', false], ClassWithFinder.condition_for_column(column, '0')
  end

  private

  def relation_class
    @klass.active_scaffold_config.model.send(:relation).class
  end
end
