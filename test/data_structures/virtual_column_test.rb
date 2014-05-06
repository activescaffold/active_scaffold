require 'test_helper'

class VirtualColumnTest < MiniTest::Test
  def setup
    @virtual_column = ActiveScaffold::DataStructures::Column.new(:fake, ModelStub)
  end

  def test_virtuality
    refute @virtual_column.column
    refute @virtual_column.association
    assert @virtual_column.virtual?
  end

  def test_sorting
    # right now, there's no intelligent sorting on virtual columns
    refute @virtual_column.sortable?
  end

  def test_searching
    # right now, there's no intelligent searching on virtual columns
    refute @virtual_column.searchable?
  end
end
