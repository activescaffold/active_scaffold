# frozen_string_literal: true

require 'test_helper'

class ActionLinkHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ActionLinkHelpers

  def test_custom_link_on_association_column_uses_action_link_authorization
    column = stub(association: stub)
    link = stub(column: nil)
    record = stub

    expects(:action_link_authorized?).with(link, record).returns([true, nil])

    assert_equal [true, nil], column_link_authorized?(link, column, record, nil)
  end

  def test_automatic_association_link_uses_associated_record_authorization
    column = stub(association: stub(collection?: false, name: :b))
    link = stub(column: column, crud_type: :read)
    record = stub
    associated = mock
    record.expects(:b).returns(associated)
    associated.expects(:authorized_for?).with(crud_type: :read, reason: true).returns([false, 'Denied'])
    expects(:action_link_authorized?).never

    assert_equal [false, 'Denied'], column_link_authorized?(link, column, record)
  end

  def test_configure_column_link_falls_back_to_authorized_show_when_edit_is_unauthorized
    column = stub
    link = ActiveScaffold::DataStructures::ActionLink.new(nil, column: column)
    link.controller_actions = %i[new edit show]
    record = stub
    associated = stub
    expects(:column_empty?).with(associated).twice.returns(false)
    expects(:column_link_authorized?).with(link, column, record, associated).twice.returns(
      [false, 'Edit denied'], [true, nil]
    )

    configured_link = configure_column_link(link, record, associated)

    assert_equal 'show', configured_link.action
    assert_equal :read, configured_link.crud_type
  end

  def test_configure_column_link_falls_back_to_authorized_list_when_edit_is_unauthorized
    column = stub
    link = ActiveScaffold::DataStructures::ActionLink.new(nil, column: column)
    link.controller_actions = %i[new edit list]
    record = stub
    associated = stub
    expects(:column_empty?).with(associated).twice.returns(false)
    expects(:column_link_authorized?).with(link, column, record, associated).twice.returns(
      [false, 'Edit denied'], [true, nil]
    )

    configured_link = configure_column_link(link, record, associated)

    assert_equal 'index', configured_link.action
    assert_equal :read, configured_link.crud_type
  end

  def test_configure_column_link_clears_unauthorized_non_update_action
    column = stub
    link = ActiveScaffold::DataStructures::ActionLink.new(nil, column: column)
    link.controller_actions = [:show]
    record = stub
    associated = stub
    stubs(:column_empty?).with(associated).returns(false)
    stubs(:column_link_authorized?).with(link, column, record, associated).returns([false, 'Show denied'])

    configured_link = configure_column_link(link, record, associated)

    assert_nil configured_link.action
    assert_equal :read, configured_link.crud_type
  end
end
