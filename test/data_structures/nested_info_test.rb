# frozen_string_literal: true

require 'test_helper'

class NestedInfoTest < ActiveSupport::TestCase
  def test_malformed_parent_scaffold_raises_bad_request
    error = assert_raises(ActionController::BadRequest) do
      ActiveScaffold::DataStructures::NestedInfo.get(
        Task,
        parent_scaffold: 'activities.', association: 'notes'
      )
    end

    assert_equal 'wrong constant name Activities.Controller', error.message
    assert_instance_of NameError, error.cause
  end

  def test_invalid_nested_association_raises_bad_request
    error = assert_raises(ActionController::BadRequest) do
      ActiveScaffold::DataStructures::NestedInfo.get(
        Task,
        parent_scaffold: 'projects', association: 'unknown'
      )
    end

    assert_equal 'Invalid nested association "unknown" for Project', error.message
  end
end
