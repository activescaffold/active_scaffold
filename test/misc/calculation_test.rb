require 'test_helper'

class ClassWithFinder
  include ActiveScaffold::Finder
  def conditions_for_collection; end
  def conditions_from_params; end
  def conditions_from_constraints; end
  def joins_for_collection; end
  def custom_finder_options
    {}
  end
  def beginning_of_chain
    active_scaffold_config.model
  end
  def conditional_get_support?; end
  def params; {}; end
end

class CalculationTest < MiniTest::Test
  def setup
    @klass = ClassWithFinder.new
    @klass.stubs(:active_scaffold_config).returns(mock { stubs(:model).returns(Building) })
    @klass.stubs(:active_scaffold_session_storage).returns({})
  end

  def test_calculation_with_conditions
    @klass.expects(:conditions_for_collection).returns(['"buildings"."name" LIKE ? OR "people"."first_name" LIKE ?', '%foo%', '%foo%'])
    @klass.expects(:active_scaffold_references).returns([:owner])
    @klass.active_scaffold_config.expects(:list).returns(mock { stubs(:count_includes).returns(nil) })

    column = mock { stubs(:field).returns('"buildings"."id"') }
    @klass.active_scaffold_config.expects(:columns).returns(mock { stubs(:"[]").returns(column) })
    query = @klass.send :calculate_query
    
    assert_equal 0, query.eager_load(:floors).count
  end
end
