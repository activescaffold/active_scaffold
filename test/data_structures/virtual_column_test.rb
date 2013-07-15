require 'test_helper'

class VirtualColumnTest < Test::Unit::TestCase
  def setup
    @virtual_column = ActiveScaffold::DataStructures::Column.new(:fake, ModelStub)
  end

  def test_virtuality
    assert !@virtual_column.column
    assert !@virtual_column.association
    assert @virtual_column.virtual?
  end

  def test_sorting
    # right now, there's no intelligent sorting on virtual columns
    assert !@virtual_column.sortable?
  end

  def test_searching
    # right now, there's no intelligent searching on virtual columns
    assert !@virtual_column.searchable?
  end
end
