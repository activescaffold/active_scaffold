# frozen_string_literal: true

require 'test_helper'

class CreateActionTest < ActionController::TestCase
  tests PeopleController

  test 'validates without persisting when create is asked to skip saving' do
    assign_params record: {first_name: 'Alice'}

    @controller.send(:do_create, skip_save: true)

    record = @controller.instance_variable_get(:@record)
    assert_equal 'Alice', record.first_name
    assert_predicate @controller, :successful?
    assert_not_predicate record, :persisted?
  end

  test 'reports active record errors raised while assigning create attributes' do
    record = Person.new
    @controller.stubs(:new_model).returns(record)
    @controller.stubs(:apply_constraints_to_record)
    @controller.stubs(:update_record_from_params).raises(ActiveRecord::RecordNotSaved, 'association failed')
    assign_params record: {first_name: 'Alice'}

    @controller.send(:do_create)

    assert_not_predicate @controller, :successful?
    assert_same record, @controller.instance_variable_get(:@record)
    assert_equal 'association failed', flash[:error]
  end

  test 'disallows create through a readonly nested association' do
    nested = stub(readonly?: true)
    @controller.stubs(:nested?).returns(true)
    @controller.stubs(:nested).returns(nested)
    @controller.expects(:authorized_for?).never

    assert_not @controller.send(:create_authorized?)
  end

  private

  def assign_params(parameters)
    @controller.params = ActionController::Parameters.new(parameters)
  end
end

class UpdateActionTest < ActionController::TestCase
  tests PeopleController

  test 'uses false instead of a true empty-value default for inline updates' do
    column = stub(default_for_empty_value: true, form_ui: nil, association: nil)
    @controller.expects(:column_value_from_param_value).with(:record, column, false).returns(false)

    assert_equal false, @controller.send(:value_for_update_column, nil, column, :record)
  end

  test 'uses an empty array when an inline collection value is blank' do
    association = stub(collection?: true)
    column = stub(default_for_empty_value: nil, form_ui: :select, association: association)
    @controller.expects(:column_value_from_param_value).with(:record, column, nil).returns(nil)

    assert_equal [], @controller.send(:value_for_update_column, nil, column, :record)
  end

  test 'refreshes the list for an inline column configured to update the table' do
    @controller.instance_variable_set(:@column, stub(inplace_edit_update: :table))
    assign_params id: '4'
    @controller.expects(:do_list)

    @controller.send(:refresh_after_update_column)

    assert_not @controller.params.key?(:id)
  end

  test 'reloads the row for an inline column configured to update its record' do
    @controller.instance_variable_set(:@column, stub(inplace_edit_update: :record))
    @controller.expects(:get_row)

    @controller.send(:refresh_after_update_column)
  end

  test 'marks stale updates unsuccessful and invokes the stale callback' do
    record = Person.new
    error = ActiveRecord::StaleObjectError.new(record, 'update')
    @controller.instance_variable_set(:@record, record)
    @controller.stubs(:update_record_from_params).raises(error)
    @controller.expects(:on_stale_object_error).with(record)
    assign_params record: {first_name: 'Alice'}

    @controller.send(:update_save)

    assert_not_predicate @controller, :successful?
    assert_predicate record.errors[:base], :present?
  end

  test 'reports record not saved errors on the updated record' do
    record = Person.new
    @controller.instance_variable_set(:@record, record)
    @controller.stubs(:update_record_from_params).raises(ActiveRecord::RecordNotSaved, 'callback stopped save')
    assign_params record: {first_name: 'Alice'}

    @controller.send(:update_save)

    assert_not_predicate @controller, :successful?
    assert_predicate record.errors[:base], :present?
  end

  test 'reports active record errors raised while assigning update attributes' do
    record = Person.new
    @controller.instance_variable_set(:@record, record)
    @controller.stubs(:update_record_from_params).raises(ActiveRecord::RecordInvalid, record)
    assign_params record: {first_name: 'Alice'}

    @controller.send(:update_save)

    assert_not_predicate @controller, :successful?
    assert_predicate flash[:error], :present?
  end

  test 'disallows update through a readonly nested association' do
    @controller.stubs(:nested?).returns(true)
    @controller.stubs(:nested).returns(stub(readonly?: true))
    @controller.expects(:authorized_for?).never

    assert_not @controller.send(:update_authorized?)
  end

  private

  def assign_params(parameters)
    @controller.params = ActionController::Parameters.new(parameters)
  end
end

class DeleteActionTest < ActionController::TestCase
  tests PeopleController

  test 'destroys the supplied record' do
    person = Person.create!(first_name: 'Alice')

    @controller.send(:do_destroy, person)

    assert_predicate @controller, :successful?
    assert_predicate person, :destroyed?
  end

  test 'turns destroy exceptions into a warning and an unsuccessful result' do
    record = mock(to_label: 'Alice')
    record.stubs(:destroy).raises(StandardError, 'database failure')
    @controller.stubs(:logger).returns(stub(warn: nil))

    @controller.send(:do_destroy, record)

    assert_not_predicate @controller, :successful?
    assert_predicate flash[:warning], :present?
  end
end

class MarkActionTest < ActionController::TestCase
  tests AddressesController

  test 'recognizes supported true values and rejects false values' do
    [true, +'TRUE', 1, +'1', +'t'].each do |value|
      assign_params value: value
      @controller.remove_instance_variable(:@mark) if @controller.instance_variable_defined?(:@mark)
      assert @controller.send(:mark?), "expected #{value.inspect} to mark"
    end

    assign_params value: +'false'
    @controller.remove_instance_variable(:@mark)
    assert_not @controller.send(:mark?)
  end

  test 'marks a member loaded with read authorization' do
    record = mock
    record.expects(:as_marked=).with(true)
    @controller.expects(:find_if_allowed).with('5', :read).returns(record)
    assign_params id: '5'

    @controller.send(:do_mark)
  end

  test 'marks the current page in page mode' do
    record = mock
    record.expects(:as_marked=).with(true)
    @controller.stubs(:active_scaffold_config).returns(stub(mark: stub(mark_all_mode: :page)))
    @controller.expects(:each_record_in_page).yields(record)
    assign_params({})

    @controller.send(:do_mark)
  end

  test 'a forced scope mark bypasses page mode' do
    record = mock
    record.expects(:as_marked=).with(true)
    @controller.stubs(:active_scaffold_config).returns(stub(mark: stub(mark_all_mode: :page)))
    @controller.expects(:each_record_in_scope).yields(record)
    assign_params mark_target: 'scope'

    @controller.send(:do_mark)
  end

  test 'demarks all records in scope mode' do
    record = mock
    record.expects(:as_marked=).with(false)
    @controller.stubs(:active_scaffold_config).returns(stub(mark: stub(mark_all_mode: :scope)))
    @controller.expects(:each_record_in_scope).yields(record)
    assign_params({})

    @controller.send(:do_demark)
  end

  private

  def assign_params(parameters)
    @controller.params = ActionController::Parameters.new(parameters)
  end
end
