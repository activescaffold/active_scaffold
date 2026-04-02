# frozen_string_literal: true

require 'test_helper'

class VirtualColumnTest < ActiveSupport::TestCase
  def setup
    @virtual_column = ActiveScaffold::DataStructures::Column.new(:fake, ModelStub)
  end

  def test_virtuality
    assert_not @virtual_column.column
    assert_not @virtual_column.association
    assert @virtual_column.virtual?
  end

  def test_sorting
    # right now, there's no intelligent sorting on virtual columns
    assert_not @virtual_column.sortable?
  end

  def test_searching
    # right now, there's no intelligent searching on virtual columns
    assert_not @virtual_column.searchable?
  end
end
