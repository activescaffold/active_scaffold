require 'test_helper'

class TablelessTest < MiniTest::Test
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
  end

  def test_find_with_through_association
    assert Building.new.files.empty?
  end

  def test_new
    assert FileModel.new
  end

  def test_association
    assert FileModel.new.person.nil?
  end
end
