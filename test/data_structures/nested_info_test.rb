# frozen_string_literal: true

require 'test_helper'

class NestedInfoTest < ActiveSupport::TestCase
  def test_builds_named_scope_information
    nested = ActiveScaffold::DataStructures::NestedInfo.get(
      Task,
      parent_scaffold: 'projects', named_scope: 'overdue', project_id: '42'
    )

    assert_instance_of ActiveScaffold::DataStructures::NestedInfoScope, nested
    assert_equal ProjectsController, nested.parent_scaffold
    assert_equal Project, nested.parent_model
    assert_equal :overdue, nested.name
    assert_equal :overdue, nested.scope
    assert_equal :project_id, nested.param_name
    assert_equal '42', nested.parent_id
    assert_empty nested.constrained_fields
    assert_equal({parent_scaffold: 'projects', named_scope: :overdue}, nested.to_params)
  end

  def test_builds_association_information_from_active_record_reflections
    nested = ActiveScaffold::DataStructures::NestedInfo.get(
      Task,
      parent_scaffold: 'projects', association: 'tasks', project_id: '42'
    )

    assert_instance_of ActiveScaffold::DataStructures::NestedInfoAssociation, nested
    assert_equal :tasks, nested.name
    assert_predicate nested, :has_many?
    assert_predicate nested, :plural_association?
    assert_not_predicate nested, :singular_association?
    assert_equal :project, nested.child_association.name
    assert_equal %i[project_id project], nested.constrained_fields
    assert nested.match_model?(Task)
    assert_not nested.match_model?(Project)
    assert_not_predicate nested, :create_with_parent?
    assert_equal({parent_scaffold: 'projects', association: :tasks, project_id: '42'}, nested.to_params)
  end

  def test_base_defaults_and_new_instance_state
    nested = ActiveScaffold::DataStructures::NestedInfo.get(
      Task,
      parent_scaffold: 'projects', named_scope: 'overdue', project_id: '42'
    )

    assert_predicate nested, :new_instance?
    assert_not_predicate nested, :new_instance?
    assert_not_predicate nested, :habtm?
    assert_not_predicate nested, :has_many?
    assert_not_predicate nested, :belongs_to?
    assert_not_predicate nested, :has_one?
    assert_not_predicate nested, :readonly?
    assert_not_predicate nested, :through_association?
    assert_not nested.sorted?(nil)
    assert_not nested.match_model?(Task)
    assert_not_predicate nested, :create_with_parent?
    assert_not nested.readonly_through_association?([])
  end

  def test_controller_not_found_returns_nil
    ActiveScaffold::DataStructures::NestedInfoScope.expects(:new).raises(ActiveScaffold::ControllerNotFound)

    assert_nil ActiveScaffold::DataStructures::NestedInfo.get(Task, parent_scaffold: 'projects')
  end

  def test_readonly_through_association_rules
    association = stub(through?: false)
    nested = association_nested(association)
    assert_not nested.readonly_through_association?([])

    association.stubs(
      through?: true,
      through_reflection: stub(through?: true),
      source_reflection: stub(through?: false, collection?: true)
    )
    assert nested.readonly_through_association?([])

    association.stubs(
      through_reflection: stub(through?: false),
      source_reflection: stub(through?: true, collection?: true)
    )
    assert nested.readonly_through_association?([])

    association.stubs(
      source_reflection: stub(through?: false, collection?: false, reverse: nil),
      through_singular?: false
    )
    assert_not nested.readonly_through_association?([])

    child = stub(through_reflection: stub(name: :membership))
    association.stubs(source_reflection: stub(through?: false, collection?: true, reverse: nil))
    nested = association_nested(association, child)
    assert_not nested.readonly_through_association?([:membership])
    assert nested.readonly_through_association?([])
  end

  def test_through_singular_association_can_be_created_with_parent
    source = stub(reverse: :owner)
    association = stub(through_singular?: true, source_reflection: source, through?: true)
    nested = association_nested(association)
    nested.stubs(has_many?: false)

    assert_predicate nested, :create_through_singular?
    assert_predicate nested, :create_with_parent?
  end

  def test_extracts_default_sorting_from_an_association_scope
    association = stub(scope: proc {})
    nested = association_nested(association)
    chain = stub(values: {order: ['tasks.priority DESC', 'tasks.id ASC']})

    assert_equal 'tasks.priority DESC, tasks.id ASC', nested.default_sorting(chain)
    assert nested.sorted?(chain)
  end

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

  private

  def association_nested(association, child_association = nil)
    ActiveScaffold::DataStructures::NestedInfoAssociation.allocate.tap do |nested|
      nested.association = association
      nested.child_association = child_association
    end
  end
end
