require 'test/unit'
require File.join(File.dirname(__FILE__), 'company')
require File.join(File.dirname(__FILE__), '../../lib/bridges/validation_reflection/lib/validation_reflection_bridge')

class ColumnWithValidationReflection < ActiveScaffold::DataStructures::Column
  include ActiveScaffold::ValidationReflectionBridge
end

class ValidationReflectionTest < Test::Unit::TestCase
  def test_set_required_for_validates_presence_of
    Company.expects(:reflect_on_validations_for).with(:name).returns([stub(:macro => :validates_presence_of)])
    column = ColumnWithValidationReflection.new(:name, Company)
    assert column.required?
  end

  def test_set_required_for_validates_inclusion_of
    Company.expects(:reflect_on_validations_for).with(:name).returns([stub(:macro => :validates_inclusion_of, :options => {})])
    column = ColumnWithValidationReflection.new(:name, Company)
    assert column.required?
  end

  def test_not_set_required_for_validates_inclusion_of_and_allow_nil
    Company.expects(:reflect_on_validations_for).with(:name).returns([stub(:macro => :validates_inclusion_of, :options => {:allow_nil => true})])
    column = ColumnWithValidationReflection.new(:name, Company)
    assert !column.required?
  end

  def test_not_set_required_for_validates_inclusion_of_and_allow_blank
    Company.expects(:reflect_on_validations_for).with(:name).returns([stub(:macro => :validates_inclusion_of, :options => {:allow_blank => true})])
    column = ColumnWithValidationReflection.new(:name, Company)
    assert !column.required?
  end

  def test_not_set_required_for_no_validation
    Company.expects(:reflect_on_validations_for).with(:name).returns([])
    column = ColumnWithValidationReflection.new(:name, Company)
    assert !column.required?
  end

  def test_set_required_for_validates_presence_of_in_association
    Company.stubs(:reflect_on_validations_for).returns([stub(:macro => :validates_presence_of)], [])
    column = ColumnWithValidationReflection.new(:main_company, Company)
    assert column.required?
  end

  def test_set_required_for_validates_presence_of_in_foreign_key
    Company.stubs(:reflect_on_validations_for).returns([], [stub(:macro => :validates_presence_of)])
    column = ColumnWithValidationReflection.new(:main_company, Company)
    assert column.required?
  end

  def test_not_set_required_for_no_validation_in_association_neither_foreign_key
    Company.stubs(:reflect_on_validations_for).returns([])
    column = ColumnWithValidationReflection.new(:main_company, Company)
    assert !column.required?
  end
end
