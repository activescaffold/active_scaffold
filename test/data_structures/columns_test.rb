# frozen_string_literal: true

require 'test_helper'

class ColumnsTest < ActiveSupport::TestCase
  def setup
    @columns = ActiveScaffold::DataStructures::Columns.new(ModelStub, :a, :b)
  end

  def test_initialization
    assert_equal ModelStub, @columns.active_record_class

    assert @columns.include?('a'), 'checking via string'
    assert @columns.include?(:b), 'checking via symbol'
    assert_not @columns.include?(:c)
  end

  def test_add
    assert_not @columns.include?(:c)
    @columns.add 'c'
    assert @columns.include?('c')

    # test the alias
    assert_not @columns.include?(:d)
    @columns << :d
    assert @columns.include?(:d)

    # try adding an array of columns
    assert_not @columns.include?(:f)
    @columns.add %i[f g]
    assert @columns.include?(:f)
    assert @columns.include?(:g)
  end

  def test_finders
    # test some basic assumptions before testing the finders
    assert @columns.include?(:a)
    assert @columns[:a].is_a?(ActiveScaffold::DataStructures::Column)

    # test the single finders
    assert @columns.find_by_name(:a).name == :a
    assert @columns[:b].name == :b

    # test the collection finders
    found = @columns.find_by_names(:a, :b)
    assert(found.any? { |c| c.name == :a })
    assert(found.any? { |c| c.name == :b })
  end

  def test_each
    names = %i[a b]
    @columns.each do |column|
      assert names.include?(column.name)
    end
  end

  def test_block_config
    assert_not @columns.include?(:d)
    assert_not @columns.include?(:c)

    @columns.configure do |config|
      # test that we can use the config object
      config << :d
      # but test that we don't have to
      add 'c'
    end

    assert @columns.include?(:d)
    assert @columns.include?(:c)
  end

  def test_inheritable_columns_are_sorted_by_weight
    @columns[:a].weight = 500
    @columns[:b].weight = 100

    assert_equal %i[b a], @columns._inheritable
  end

  def test_inheritable_columns_can_be_replaced_without_resorting
    @columns._inheritable = [:b]
    @columns.add :a

    assert_equal %i[b a], @columns._inheritable
  end

  def test_exclude_only_removes_the_column_from_inheritance
    @columns.exclude 'a'

    assert @columns.include?(:a)
    assert_not_includes @columns._inheritable, :a
    assert_includes @columns._inheritable, :b
  end

  def test_adds_readonly_columns_delegated_through_a_singular_association
    columns = ActiveScaffold::DataStructures::Columns.new(ModelStub, :other_model)

    columns.add_association_columns(:other_model, :a)
    delegated_column = columns[:a]

    assert_equal ModelStub, delegated_column.active_record_class
    assert_equal :other_model, delegated_column.delegated_association.name
    assert_not_includes columns._inheritable, :a

    columns.add_association_columns(:other_model, :a)
    assert_same delegated_column, columns[:a]
  end

  def test_rejects_invalid_associations_for_delegated_columns
    error = assert_raises(ArgumentError) { @columns.add_association_columns(:missing, :c) }
    assert_equal 'unknown column missing', error.message

    error = assert_raises(ArgumentError) { @columns.add_association_columns(:a, :c) }
    assert_equal 'column a is not an association', error.message

    columns = ActiveScaffold::DataStructures::Columns.new(ModelStub, :other_models)
    error = assert_raises(ArgumentError) { columns.add_association_columns(:other_models, :c) }
    assert_equal 'column other_models is not singular association', error.message

    columns = ActiveScaffold::DataStructures::Columns.new(Contact, :contactable)
    error = assert_raises(ArgumentError) { columns.add_association_columns(:contactable, :name) }
    assert_equal 'column contactable is polymorphic association', error.message
  end
end
