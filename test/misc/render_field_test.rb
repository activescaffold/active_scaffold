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

  private

  def assign_params(params)
    @controller.params = ActionController::Parameters.new(params)
  end
end
