# frozen_string_literal: true

require 'test_helper'

class RenderFieldTest < ActionController::TestCase
  tests PeopleController

  test 'prepares changed column and record for update columns' do
    assign_params column: 'first_name', value: 'Ada'

    @controller.send(:render_field_for_update_columns)

    assert_equal :first_name, @controller.instance_variable_get(:@column).name
    assert_equal :create, @controller.instance_variable_get(:@form_action)
    assert_equal 'Ada', @controller.instance_variable_get(:@record).first_name
    assert_same @controller.active_scaffold_config.create.columns,
                @controller.instance_variable_get(:@main_columns)
  end

  test 'override calling super can inspect and change prepared state' do
    override = Module.new do
      def render_field_for_update_columns
        super
        @override_column = @column
        @main_columns = active_scaffold_config.build_action_columns(:update, [:last_name])
      end
    end
    @controller.singleton_class.prepend(override)
    assign_params column: 'first_name', value: 'Ada'

    @controller.send(:render_field_for_update_columns)

    assert_equal :first_name, @controller.instance_variable_get(:@override_column).name
    assert_equal [:last_name], @controller.instance_variable_get(:@main_columns).to_a
  end

  test 'conditional override can bypass default processing' do
    override = Module.new do
      def render_field_for_update_columns
        if params[:custom]
          @record = Person.new(first_name: 'Custom')
        else
          super
        end
      end
    end
    @controller.singleton_class.prepend(override)
    assign_params custom: true, column: 'first_name', value: 'Ignored'

    @controller.send(:render_field_for_update_columns)

    assert_equal 'Custom', @controller.instance_variable_get(:@record).first_name
    assert_nil @controller.instance_variable_get(:@column)
  end

  test 'uses configured subform columns for scoped fields' do
    parent_column = stub(
      form_ui_options: {subform_columns: [:first_name]},
      options: {}
    )
    @controller.stubs(:main_form_controller).returns(PeopleController)
    @controller.stubs(:parent_column).with(PeopleController, '[buildings]').returns(parent_column)
    assign_params scope: '[buildings]', source_id: 'source-1'

    @controller.send(:process_render_field_params)

    assert_equal 'source-1', @controller.instance_variable_get(:@source_id)
    assert_equal :subform, @controller.instance_variable_get(:@form_action)
    assert_equal [:first_name], @controller.instance_variable_get(:@main_columns).to_a
  end

  test 'uses an explicitly requested enabled form action' do
    @controller.stubs(:active_scaffold_config).returns(stub(actions: [:field_search]))
    assign_params form_action: 'field_search'

    assert_equal :field_search, @controller.send(:render_field_form_action)
    assert_not @controller.params.key?(:form_action)
  end

  test 'add tab prepares the selected column and record' do
    columns = stub
    column = ActiveScaffold::DataStructures::ActionColumns.new
    column.tabbed_by = :status
    record = stub
    @controller.instance_variable_set(:@main_columns, columns)
    @controller.instance_variable_set(:@scope, '[tasks]')
    @controller.expects(:process_render_field_params)
    columns.expects(:find_by_name).with('status').returns(column)
    @controller.expects(:updated_record_with_form).with(columns, {}, '[tasks]').returns(record)
    assign_params column: 'status', tabbed_by: 'status'

    @controller.send(:add_tab)

    assert_same column, @controller.instance_variable_get(:@column)
    assert_same record, @controller.instance_variable_get(:@record)
  end

  test 'field search preserves an array for a singular association' do
    record = Person.new
    column = stub(association: stub(singular?: true))
    @controller.instance_variable_set(:@form_action, :field_search)
    @controller.stubs(:new_model).returns(record)
    @controller.stubs(:apply_constraints_to_record).with(record)
    @controller.expects(:update_column_from_params).never
    assign_params({})

    result = @controller.send(:updated_record_with_column, column, %w[1 2], nil)

    assert_same record, result
    assert_equal %w[1 2], @controller.instance_variable_get(:@value)
  end

  test 'copies a saved record into a clean form record' do
    saved = Person.new(first_name: 'Alice')
    saved.id = 42
    config = @controller.active_scaffold_config
    relation = config.model.all
    @controller.stubs(:preload_for_form).returns([:buildings])
    config.model.expects(:preload).with([:buildings]).returns(relation)
    @controller.expects(:find_if_allowed).with(42, :read, relation).returns(saved)

    copy = @controller.send(:copy_data_from_saved_record, 42)

    assert_not_same saved, copy
    assert_equal 42, copy.id
    assert_equal 'Alice', copy.first_name
    assert_not_predicate copy, :changed?
  end

  test 'finds parent column through nested collection scope' do
    assign_params record: {buildings: {'1' => {}}}

    column = @controller.send(
      :parent_column,
      PeopleController,
      '[buildings][1][floors]'
    )

    assert_equal :floors, column.name
  end

  test 'finds parent column after polymorphic association' do
    assign_params record: {addressable_type: 'Person'}

    column = @controller.send(
      :parent_column,
      AddressesController,
      '[addressable][buildings]'
    )

    assert_equal :buildings, column.name
  end

  test 'splits a nested scope into its parts' do
    assert_equal %w[buildings 1 floors], @controller.send(:scope_parts, '[buildings][1][floors]')
    assert_empty @controller.send(:scope_parts, nil)
  end

  test 'finds attributes through a nested scope' do
    attributes = {
      'buildings' => {
        '1' => {
          'floors' => {'2' => {name: 'First floor'}}
        }
      }
    }

    scoped_attributes = @controller.send(:attributes_from_scope, attributes, '[buildings][1][floors][2]')

    assert_equal({name: 'First floor'}, scoped_attributes)
  end

  test 'returns nil when attributes do not contain the scope' do
    attributes = {'buildings' => {}}

    assert_nil @controller.send(:attributes_from_scope, attributes, '[buildings][1][floors]')
  end

  test 'finds an existing record in a collection scope' do
    person = Person.new
    building = person.buildings.build(name: 'Tower')
    building.id = 42

    result = @controller.send(:find_from_scope, person, '[buildings][42]')

    assert_same building, result
  end

  test 'finds a generated record missing from the association target' do
    person = Person.new
    building = Building.new(name: 'Generated')
    @controller.instance_variable_set(:@new_records, {Building => {'7' => building}})

    result = @controller.send(:find_from_scope, person, '[buildings][7]')

    assert_same building, result
  end

  test 'copies attributes and loaded associations without dirty changes' do
    person = Person.new(first_name: 'Alice')
    building = person.buildings.build(name: 'Tower')

    copy = @controller.send(:copy_attributes, person)

    assert_equal 'Alice', copy.first_name
    assert_equal [building], copy.buildings
    assert_not_predicate copy, :changed?
  end

  private

  def assign_params(params)
    @controller.params = ActionController::Parameters.new(params)
  end
end
