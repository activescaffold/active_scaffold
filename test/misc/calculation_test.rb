require 'test_helper'
require 'class_with_finder'

class CalculationTest < MiniTest::Test
  def setup
    @buildings = []
    @buildings << Building.create { |b| b.create_owner(:first_name => 'foo') }
    @buildings << Building.create(:name => 'foo bar')
    @buildings << Building.create

    @klass = ClassWithFinder.new
    @klass.active_scaffold_config.stubs(:model).returns(Building)
  end

  def teardown
    @buildings.each(&:destroy).map(&:owner).compact.each(&:destroy)
  end

  def test_calculation_with_conditions
    @klass.expects(:conditions_for_collection).returns(['"buildings"."name" LIKE ? OR "people"."first_name" LIKE ?', '%foo%', '%foo%'])
    @klass.expects(:active_scaffold_references).returns([:owner])
    @klass.active_scaffold_config.expects(:list).returns(mock.tap { |m| m.stubs(:count_includes).returns(nil) })

    column = mock.tap { |m| m.stubs(:field).returns('"buildings"."id"') }
    @klass.active_scaffold_config.expects(:columns).returns(mock.tap { |m| m.stubs(:"[]").returns(column) })
    query = @klass.send :calculate_query
    assert_equal 2, query.count
  end

  def test_calculation_without_conditions
    @klass.stubs(:active_scaffold_references).returns([:owner])
    @klass.active_scaffold_config.expects(:list).returns(mock.tap { |m| m.stubs(:count_includes).returns(nil) })

    column = mock.tap { |m| m.stubs(:field).returns('"buildings"."id"') }
    @klass.active_scaffold_config.expects(:columns).returns(mock.tap { |m| m.stubs(:"[]").returns(column) })
    query = @klass.send :calculate_query
    assert_equal Building.count, query.count
  end
end
