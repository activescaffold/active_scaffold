require 'test_helper'

class StandardColumnTest < MiniTest::Test
  def setup
    @standard_column = ActiveScaffold::DataStructures::Column.new(ModelStub.columns.first.name, ModelStub)
  end

  def test_virtuality
    assert @standard_column.column
    refute @standard_column.virtual?
  end

  def test_sorting
    hash = {:sql => '"model_stubs"."a"'}
    assert @standard_column.sortable?
    assert_equal hash, @standard_column.sort # check default
  end

  def test_searching
    assert @standard_column.searchable?
    assert_equal ['"model_stubs"."a"'], @standard_column.search_sql # check default
  end
end
