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
end
