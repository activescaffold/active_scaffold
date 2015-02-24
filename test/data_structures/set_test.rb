require 'test_helper'

class SetTest < MiniTest::Test
  def setup
    @items = ActiveScaffold::DataStructures::Set.new(:a, :b)
  end

  def test_initialization
    assert @items.include?(:a)
    assert @items.include?(:b)
    refute @items.include?(:c)
  end

  def test_exclude
    # exclude with a symbol
    assert @items.include?(:b)
    @items.exclude :b
    refute @items.include?(:b)

    # exclude with a string
    assert @items.include?(:a)
    @items.exclude 'a'
    refute @items.include?(:a)
  end

  def test_exclude_array
    # exclude with a symbol
    assert @items.include?(:b)
    @items.exclude [:a, :b]
    refute @items.include?(:b)
    refute @items.include?(:a)
  end

  def test_remove
    assert @items.include?(:a)
    @items.remove 'a'
    refute @items.include?(:a)
  end

  def test_add
    # try adding a simple column using a string
    refute @items.include?(:c)
    @items.add 'c'
    assert @items.include?(:c)

    # try adding a simple column using a symbol
    refute @items.include?(:d)
    @items.add :d
    assert @items.include?(:d)

    # test that << also adds
    refute @items.include?(:e)
    @items << 'e'
    assert @items.include?(:e)

    # try adding an array of columns
    refute @items.include?(:f)
    @items.add [:f, :g]
    assert @items.include?(:f)
    assert @items.include?(:g)
  end

  def test_length
    assert_equal 2, @items.length
  end

  def test_block_config
    @items.configure do |config|
      # we may use the config argument
      config.add :c
      # or we may not
      exclude :b
    end

    assert @items.include?(:c)
    refute @items.include?(:b)
  end

  def test_include
    assert @items.include?(:a)
    assert @items.include?(:b)
    refute @items.include?(:d)
  end
end
