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
end
