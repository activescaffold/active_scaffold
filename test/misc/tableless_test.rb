# frozen_string_literal: true

require 'test_helper'

class TablelessTest < ActiveSupport::TestCase
  def test_find_all
    assert FileModel.all.to_a.empty?
  end

  def test_where
    assert FileModel.where(name: 'file').to_a.empty?
  end

  def test_where_using_assoc
    assert FileModel.includes(:person).where(people: {name: 'Name'}).to_a.empty?
  end

  def test_count
    assert_equal 0, FileModel.count
  end

  def test_find_by_id
    assert_raises ActiveRecord::RecordNotFound do
      FileModel.find('filename')
    end
  end

  def test_find_with_association
    assert Person.new.files.empty?
    @person = Person.new
    @person.save(validate: false)
    assert_not @person.files.empty?
    assert @person.files.exists?
    assert_equal @person.id, @person.files.first.person_id
  end

  def test_tableless_assoc_with_dependent
    @person = Person.new
    @person.save(validate: false)
    assert @person.destroy
  end

  def test_find_with_through_association
    assert Building.new.files.empty?
    @building = Building.new
    @building.save(validate: false)
    assert @building.files.empty?
    assert_equal [], @building.files.to_a
  end

  def test_new
    assert FileModel.new
  end

  def test_association
    assert FileModel.new.person.nil?
  end
end
