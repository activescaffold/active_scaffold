require 'test_helper'

class ActionsTest < MiniTest::Test
  def setup
    @actions = ActiveScaffold::DataStructures::Actions.new(:a, 'b')
  end

  def test_initialization
    assert @actions.include?('a')
    assert @actions.include?(:b)
    refute @actions.include?(:c)
  end

  def test_exclude
    assert @actions.include?('b')
    @actions.exclude :b
    refute @actions.include?(:b)
  end

  def test_add
    refute @actions.include?(:c)
    @actions.add 'c'
    assert @actions.include?('c')
  end
end
