require 'test_helper'

class ActionLinkTest < MiniTest::Test
  def setup
    @link = ActiveScaffold::DataStructures::ActionLink.new('foo')
  end

  def test_simple_attributes
    assert_equal 'foo', @link.action
    @link.action = 'bar'
    assert_equal 'bar', @link.action

    hash = {:a => :b}
    @link.parameters = hash
    assert_equal hash, @link.parameters

    @link.label = 'hello world'
    assert_equal 'hello world', @link.label

    refute @link.confirm
    @link.confirm = true
    assert @link.confirm
    assert @link.confirm?

    assert_equal 'bar_authorized?', @link.security_method

    assert_equal false, @link.security_method_set?
    @link.security_method = 'blueberry_pie'
    assert_equal true, @link.security_method_set?
    assert_equal 'blueberry_pie', @link.security_method

    @link.type = :collection
    assert_equal :collection, @link.type
    @link.type = :member
    assert_equal :member, @link.type

    assert_equal :get, @link.method
    @link.method = :put
    assert_equal :put, @link.method
  end

  def test_position
    @link.position = true

    @link.type = :collection
    assert_equal :top, @link.position

    @link.type = :member
    assert_equal :replace, @link.position

    @link.position = :before
    assert_equal :before, @link.position

    @link.position = false
    assert_equal false, @link.position
  end

  def test_presentation_style
    # default
    assert @link.inline?
    refute @link.popup?
    refute @link.page?

    @link.popup = true
    refute @link.inline?
    assert @link.popup?
    refute @link.page?

    @link.page = true
    refute @link.inline?
    refute @link.popup?
    assert @link.page?

    @link.inline = true
    assert @link.inline?
    refute @link.popup?
    refute @link.page?
  end
end
