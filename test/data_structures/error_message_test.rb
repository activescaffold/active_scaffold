require 'test_helper'

class ErrorMessageTest < MiniTest::Test
  def setup
    @error = ActiveScaffold::DataStructures::ErrorMessage.new 'foo'
  end

  def test_attributes
    assert @error.public_attributes.key?(:error)
    assert_equal 'foo', @error.public_attributes[:error]
  end

  def test_xml
    xml = Hash.from_xml(@error.to_xml)
    assert xml.key?('errors')
    assert xml['errors'].key?('error')
    assert_equal 'foo', xml['errors']['error']
  end

  def test_yaml
    yml = YAML.load(@error.to_yaml)
    assert yml.key?(:error)
    assert_equal 'foo', yml[:error]
  end
end
