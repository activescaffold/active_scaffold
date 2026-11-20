# frozen_string_literal: true

require 'test_helper'

class SubformHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def test_unauthorized_new_record_renders_create_column_readonly
    column = ActiveScaffold::DataStructures::Column.new(:first_name, Person)
    record = stub(new_record?: true)
    record.expects(:authorized_for?).with(crud_type: :create, column: :first_name).returns(false)
    expects(:form_attribute).with(
      column, record, '[contacts][0]', only_value: true, col_class: nil
    ).returns('readonly create field')

    html = active_scaffold_render_subform_column(
      column, '[contacts][0]', :create, false, record: record
    )

    assert_equal 'readonly create field', html
  end

  def test_unauthorized_persisted_record_renders_update_column_readonly
    column = ActiveScaffold::DataStructures::Column.new(:first_name, Person)
    record = stub(new_record?: false)
    record.expects(:authorized_for?).with(crud_type: :update, column: :first_name).returns(false)
    expects(:form_attribute).with(
      column, record, '[contacts][1]', only_value: true, col_class: nil
    ).returns('readonly update field')

    html = active_scaffold_render_subform_column(
      column, '[contacts][1]', :update, false, record: record
    )

    assert_equal 'readonly update field', html
  end

  def test_dependent_destroy_hides_remove_link_when_record_cannot_be_deleted
    association = stub(singular?: false, dependent: :destroy)
    association_column = stub(association: association)
    record = stub
    record.expects(:authorized_for?).with(crud_type: :delete, reason: true).returns([false, 'Delete denied'])

    html = active_scaffold_subform_record_actions(association_column, record, false, '[contacts][0]')

    assert_not_includes html, '<a'
    assert_includes html, 'Delete denied'
  end

  def test_remove_link_does_not_require_delete_authorization_without_dependent_delete
    association = stub(singular?: false, dependent: nil)
    association_column = stub(association: association)
    record = mock
    record.expects(:authorized_for?).never

    html = active_scaffold_subform_record_actions(association_column, record, false, '[contacts][0]')

    assert_includes html, '<a'
    assert_includes html, 'class="destroy"'
  end

  def test_reverse_association_to_parent_is_automatically_skipped
    parent_record = Project.new
    parent_column = ActiveScaffold::DataStructures::Column.new(:tasks, Project)
    reverse_column = ActiveScaffold::DataStructures::Column.new(:project, Task)
    unrelated_column = ActiveScaffold::DataStructures::Column.new(:category, Task)

    assert_not in_subform?(reverse_column, parent_record, parent_column)
    assert in_subform?(unrelated_column, parent_record, parent_column)
  end

  def test_polymorphic_association_without_reverse_is_skipped
    parent_record = Person.new
    parent_column = ActiveScaffold::DataStructures::Column.new(:contacts, Person)
    polymorphic_column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)

    assert_nil polymorphic_column.association.reverse
    assert_not in_subform?(polymorphic_column, parent_record, parent_column)
  end

  def test_add_existing_uses_record_select_controller
    record_select_config = stub(model: Person)
    controller.singleton_class.define_method(:record_select_config) { record_select_config }
    controller.singleton_class.send(:private, :record_select_config)
    stubs(:record_select_config).returns(record_select_config)
    stubs(:active_scaffold_controller_for).with(Person).returns(stub(controller_path: 'people'))
    captured = nil
    define_singleton_method(:record_select_field) do |name, value, options|
      captured = [name, value, options]
      '<input class="record-select">'.html_safe
    end

    html = active_scaffold_add_existing_input(name: 'associated_id', object: Person.new)

    assert_equal '<input class="record-select">', html
    assert_equal 'associated_id', captured[0]
    assert_nil captured[1]
    assert_equal 'people', captured[2][:controller]
    assert_equal 'off', captured[2][:autocomplete]
    assert_equal 'text-input', captured[2][:class]
    assert_equal 'Person', active_scaffold_add_existing_label
  ensure
    controller.singleton_class.send(:remove_method, :record_select_config)
  end
end
