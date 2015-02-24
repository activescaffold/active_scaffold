require 'test_helper'

class ErrorMessageTest < MiniTest::Test
  def setup
    @error = ActiveScaffold::DataStructures::ErrorMessage.new 'foo'
  end

  def test_attributes
    assert @error.public_attributes.has_key?(:error)
    assert_equal 'foo', @error.public_attributes[:error]
  end

  def test_xml
    xml = Hash.from_xml(@error.to_xml)
    assert xml.has_key?('errors')
    assert xml['errors'].has_key?('error')
    assert_equal 'foo', xml['errors']['error']
  end

  def test_yaml
    yml = YAML.load(@error.to_yaml)
    assert yml.has_key?(:error)
    assert_equal 'foo', yml[:error]
  end
end
