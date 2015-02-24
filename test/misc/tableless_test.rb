require 'test_helper'

class TablelessTest < MiniTest::Test
  def test_find_all
    assert FileModel.all.to_a.empty?
  end

  def test_find_by_id
    assert_raises ActiveRecord::RecordNotFound do
      FileModel.find('filename')
    end
  end

  def test_find_with_association
    assert Person.new.files.empty?
  end
end
