require 'test_helper'

class TablelessTest < MiniTest::Test
  def test_find_all
    assert_equal [], FileModel.all
  end
  
  def test_find_by_id
    assert_raises ActiveRecord::RecordNotFound do
      FileModel.find('filename')
    end
  end
  
  def test_find_with_association
    assert_equal [], Person.new.files
  end
end
  
