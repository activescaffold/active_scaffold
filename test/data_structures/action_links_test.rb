# frozen_string_literal: true

require 'test_helper'

class ActionLinksTest < ActiveSupport::TestCase
  def setup
    @links = ActiveScaffold::DataStructures::ActionLinks.new
  end

  def test_add_and_find
    # test adding with a shortcut
    @links.add 'foo/bar'

    assert_equal(1, @links.count { true })
    assert_equal 'foo/bar', @links.find { true }.action
    assert_equal 'foo/bar', @links['foo/bar'].action

    # test adding an ActionLink object directly
    @links.add ActiveScaffold::DataStructures::ActionLink.new('hello/world')

    assert_equal(2, @links.count { true })

    # test the << alias
    @links << 'a/b'

    assert_equal(3, @links.count { true })
  end

  def test_array_access
    @link1 = ActiveScaffold::DataStructures::ActionLink.new 'foo/bar'
    @link2 = ActiveScaffold::DataStructures::ActionLink.new 'hello_world'

    @links.add @link1
    @links.add @link2

    assert_equal @link1, @links[@link1.action]
    assert_equal @link2, @links[@link2.action]
  end

  def test_empty
    assert @links.empty?
    @links.add 'a'
    assert_not @links.empty?
  end

  def test_cloning
    @links.add 'foo/bar'
    @links_copy = @links.clone

    assert_not @links.equal?(@links_copy)
    assert_not @links['foo/bar'].equal?(@links_copy['foo/bar'])
  end

  def test_each
    @links.add 'foo', type: :collection
    @links.add 'bar', type: :member

    @links.collection.each do |link|
      assert_equal 'foo', link.action
    end
    @links.member.each do |link|
      assert_equal 'bar', link.action
    end
  end

  def test_delete
    @links.add 'foo'
    @links.add 'bar'

    @links.delete :foo
    assert @links['foo'].nil?
    begin
      @links.delete :foo
      @links.delete 'foo'
    rescue StandardError
      assert false, "deleting from action links when item doesn't exist should not throw an error"
    end
    assert_not @links['bar'].nil?
  end
end
