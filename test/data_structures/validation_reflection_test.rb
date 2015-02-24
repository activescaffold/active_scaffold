require 'test_helper'

class ValidationReflectionTest < MiniTest::Test
  def test_set_required_for_validates_presence_of
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    refute column.required?
    Company.expects(:validators_on).with(:name).returns([ActiveModel::Validations::PresenceValidator.new(:attributes => :name)])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    assert column.required?
  end

  def test_set_required_for_validates_inclusion_of
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    refute column.required?
    Company.expects(:validators_on).with(:name).returns([ActiveModel::Validations::InclusionValidator.new(:attributes => :name, :in => [])])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    assert column.required?
  end

  def test_not_set_required_for_validates_inclusion_of_and_allow_nil
    Company.expects(:validators_on).with(:name).returns([ActiveModel::Validations::InclusionValidator.new(:attributes => :name, :in => [], :allow_nil => true)])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    refute column.required?
  end

  def test_not_set_required_for_validates_inclusion_of_and_allow_blank
    Company.expects(:validators_on).with(:name).returns([ActiveModel::Validations::InclusionValidator.new(:attributes => :name, :in => [], :allow_blank => true)])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    refute column.required?
  end

  def test_not_set_required_for_no_validation
    Company.expects(:validators_on).with(:name).returns([])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    refute column.required?
  end

  def test_set_required_for_validates_presence_of_in_association
    column = ActiveScaffold::DataStructures::Column.new(:main_company, Company)
    refute column.required?
    Company.expects(:validators_on).with(:main_company).returns([ActiveModel::Validations::PresenceValidator.new(:attributes => :main_company)])
    column = ActiveScaffold::DataStructures::Column.new(:main_company, Company)
    assert column.required?
  end

  def test_not_set_required_for_no_validation_in_association_neither_foreign_key
    Company.expects(:validators_on).returns([])
    column = ActiveScaffold::DataStructures::Column.new(:main_company, Company)
    refute column.required?
  end

  def test_override_required
    Company.expects(:validators_on).with(:name).returns([ActiveModel::Validations::PresenceValidator.new(:attributes => :name)])
    column = ActiveScaffold::DataStructures::Column.new(:name, Company)
    assert column.required?
    column.required = false
    refute column.required?
  end
end
