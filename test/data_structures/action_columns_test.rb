# frozen_string_literal: true

require 'test_helper'
# require 'test/model_stub'
# require File.join(File.dirname(__FILE__), '../../lib/active_scaffold/data_structures/set.rb')

class ActionColumnsTest < ActiveSupport::TestCase
  def setup
    @columns = ActiveScaffold::DataStructures::ActionColumns.new(%i[a b])
    @columns.action = stub(core: stub(model_id: 'model_stub'), user_settings_key: :'model_stub_active_scaffold/config/test')
  end

  def test_label
    assert_not_equal 'foo', @columns.label
    @columns.label = 'foo'
    assert_equal 'foo', @columns.label
  end

  def test_initialization
    assert @columns.include?(:a)
    assert @columns.include?(:b)
    assert_not @columns.include?(:c)
  end

  def test_exclude
    # exclude with a symbol
    assert @columns.include?(:b)
    @columns.exclude :b
    assert_not @columns.include?(:b)

    # exclude with a string
    assert @columns.include?(:a)
    @columns.exclude 'a'
    assert_not @columns.include?(:a)
  end

  def test_exclude_array
    # exclude with a symbol
    assert @columns.include?(:b)
    @columns.exclude %i[a b]
    assert_not @columns.include?(:b)
    assert_not @columns.include?(:a)
  end

  def test_add
    # try adding a simple column using a string
    assert_not @columns.include?(:c)
    @columns.add 'c'
    assert @columns.include?(:c)

    # try adding a simple column using a symbol
    assert_not @columns.include?(:d)
    @columns.add :d
    assert @columns.include?(:d)

    # test that << also adds
    assert_not @columns.include?(:e)
    @columns << :e
    assert @columns.include?(:e)

    # try adding an array of columns
    assert_not @columns.include?(:f)
    @columns.add %i[f g]
    assert @columns.include?(:f)
    assert @columns.include?(:g)
  end

  def test_length
    assert_equal 2, @columns.length
  end

  def test_add_subgroup
    # first, use @columns.add directly
    @c2 = ActiveScaffold::DataStructures::ActionColumns.new
    @columns.add @c2
    assert(@columns.any?(@c2))

    # then use the shortcut
    @columns.add_subgroup 'foo' do
      # add a subgroup
    end
    assert(@columns.any? { |c| c.respond_to?(:label) && c.label == 'foo' })
  end

  def test_block_config
    @columns.configure do |config|
      # we may use the config argument
      config.add :c
      # or we may not
      exclude :b
      add_subgroup 'my subgroup' do
        add :e
      end
    end

    assert @columns.include?(:c)
    assert_not @columns.include?(:b)
    @columns.each do |c|
      next unless c.is_a? ActiveScaffold::DataStructures::Columns

      assert c.include?(:e)
      assert_equal 'my subgroup', c.name
    end
  end

  def test_include
    @columns.add_subgroup 'foo' do
      add :c
    end

    assert @columns.include?(:a)
    assert @columns.include?(:b)
    assert @columns.include?(:c)
    assert_not @columns.include?(:d)
  end

  # --- layout :multiple tests ---

  def test_layout_defaults_to_nil
    assert_nil @columns.layout
  end

  def test_layout_multiple_moves_columns_to_first_group
    @columns.layout = :multiple

    assert_equal :multiple, @columns.layout
    group = @columns[0]
    assert_instance_of ActiveScaffold::DataStructures::ActionColumns, group
    assert group.include?(:a)
    assert group.include?(:b)
    assert_nil @columns[1]
  end

  def test_layout_multiple_on_empty_columns
    empty = ActiveScaffold::DataStructures::ActionColumns.new
    empty.action = @columns.action
    empty.layout = :multiple

    assert_equal :multiple, empty.layout
    assert_nil empty[0]
  end

  def test_layout_multiple_integer_indexing
    @columns.layout = :multiple

    assert_instance_of ActiveScaffold::DataStructures::ActionColumns, @columns[0]
    assert_nil @columns[1]
  end

  def test_layout_multiple_bracket_assign_replaces_group
    @columns.layout = :multiple
    @columns[0] = %i[c d e]

    group = @columns[0]
    assert group.include?(:c)
    assert group.include?(:d)
    assert group.include?(:e)
    assert_not group.include?(:a)
  end

  def test_layout_multiple_bracket_assign_creates_new_group
    @columns.layout = :multiple
    @columns[1] = %i[c d]

    assert_instance_of ActiveScaffold::DataStructures::ActionColumns, @columns[1]
    assert @columns[1].include?(:c)
    assert @columns[1].include?(:d)
    # first group unchanged
    assert @columns[0].include?(:a)
  end

  def test_layout_multiple_bracket_assign_out_of_range
    @columns.layout = :multiple
    # only group 0 exists, so [2]= should raise
    assert_raises(ArgumentError) { @columns[2] = %i[c d] }
  end

  def test_layout_multiple_bracket_assign_raises_without_multiple
    assert_raises(RuntimeError) { @columns[0] = %i[c d] }
  end

  def test_layout_multiple_add_creates_group
    @columns.layout = :multiple
    @columns << %i[c d]

    assert_instance_of ActiveScaffold::DataStructures::ActionColumns, @columns[1]
    assert @columns[1].include?(:c)
    assert @columns[1].include?(:d)
  end

  def test_layout_multiple_add_single_column_creates_group
    @columns.layout = :multiple
    @columns << :c

    assert_instance_of ActiveScaffold::DataStructures::ActionColumns, @columns[1]
    assert @columns[1].include?(:c)
  end

  def test_layout_multiple_add_subgroup_raises
    @columns.layout = :multiple
    assert_raises(RuntimeError) { @columns.add_subgroup('foo') { add :c } }
  end

  def test_layout_single_merges_groups
    @columns.layout = :multiple
    @columns[0] = %i[a b]
    @columns[1] = %i[c d]
    @columns.layout = :single

    assert_equal :single, @columns.layout
    assert @columns.include?(:a)
    assert @columns.include?(:b)
    assert @columns.include?(:c)
    assert @columns.include?(:d)
    # should be flat symbols, not ActionColumns
    @columns.each do |item|
      assert_kind_of Symbol, item
    end
  end

  def test_layout_multiple_idempotent
    @columns.layout = :multiple
    first_group = @columns[0]
    @columns.layout = :multiple
    # setting :multiple again should not re-wrap
    assert_equal first_group, @columns[0]
  end

  def test_set_values_resets_layout
    @columns.layout = :multiple
    @columns.set_values(:x, :y)

    assert_nil @columns.layout
    assert @columns.include?(:x)
    assert @columns.include?(:y)
    @columns.each { |item| assert_kind_of Symbol, item }
  end

  def test_layout_multiple_include_searches_groups
    @columns.layout = :multiple
    @columns[1] = %i[c d]

    assert @columns.include?(:a)
    assert @columns.include?(:c)
    assert_not @columns.include?(:z)
  end

  def test_layout_multiple_groups_have_action_set
    @columns.layout = :multiple

    assert_equal @columns.action, @columns[0].action
    @columns[1] = %i[c d]
    assert_equal @columns.action, @columns[1].action
  end

  def test_layout_multiple_group_supports_subgroup
    @columns.layout = :multiple
    @columns[0].add_subgroup 'Advanced' do
      add :x
    end

    assert @columns[0].include?(:x)
  end
end
