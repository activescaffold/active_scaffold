require 'test_helper'
require 'model_stub'

class AssociationColumnTest < MiniTest::Test
  def setup
    @association_column = ActiveScaffold::DataStructures::Column.new('other_model', ModelStub)
  end

  def test_virtuality
    assert @association_column.association
    refute @association_column.virtual?
  end

  def test_sorting
    # sorting on association columns is not defined
    assert_equal false, @association_column.sort
  end

  def test_searching
    # by default searching on association columns uses primary key
    assert @association_column.searchable?
    assert_equal ['"model_stubs"."id"'], @association_column.search_sql
  end

  def test_association
    assert @association_column.association.is_a?(ActiveRecord::Reflection::AssociationReflection)
  end

  def test_includes
    assert_equal [:other_model], @association_column.includes
  end

  def test_plurality
    assert @association_column.singular_association?
    refute @association_column.plural_association?

    plural_association_column = ActiveScaffold::DataStructures::Column.new('other_models', ModelStub)
    assert plural_association_column.plural_association?
    refute plural_association_column.singular_association?
  end
end
