# frozen_string_literal: true

require 'test_helper'

class ActionsTest < ActiveSupport::TestCase
  def setup
    @actions = ActiveScaffold::DataStructures::Actions.new(:a, 'b')
  end

  def test_initialization
    assert @actions.include?('a')
    assert @actions.include?(:b)
    assert_not @actions.include?(:c)
  end

  def test_exclude
    assert @actions.include?('b')
    @actions.exclude :b
    assert_not @actions.include?(:b)
  end

  def test_add
    assert_not @actions.include?(:c)
    @actions.add 'c'
    assert @actions.include?('c')
  end
end
