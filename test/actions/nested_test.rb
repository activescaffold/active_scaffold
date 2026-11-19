# frozen_string_literal: true

require 'test_helper'

class NestedActionTest < ActionController::TestCase
  tests PeopleController

  setup do
    @person = Person.create!(first_name: 'Alice')
    @role = Role.create!(name: 'Editor')
    @association = Role.reflect_on_association(:people)
    @nested = stub(association: @association, habtm?: true)
    @controller.stubs(:nested).returns(@nested)
    @controller.stubs(:nested_parent_record).returns(@role)
  end

  test 'adds an existing record to a HABTM association' do
    assign_params associated_id: @person.id

    assert @controller.send(:do_add_existing)
    assert_equal [@person], @role.reload.people
    assert @controller.send(:successful?)
  end

  test 'reports an existing HABTM association without duplicating it' do
    @role.people << @person
    assign_params associated_id: @person.id

    assert @controller.send(:do_add_existing)

    assert @controller.instance_variable_get(:@association_already_exists)
    assert_equal 1, @role.reload.people.count
    assert_predicate flash[:warning], :present?
  end

  test 'shallow destroy removes only the HABTM association' do
    @role.people << @person
    assign_params id: @person.id

    @controller.send(:do_destroy_existing)

    assert_empty @role.reload.people
    assert_predicate Person.find(@person.id), :persisted?
  end

  test 'authorization delegates to the nested parent association' do
    @role.expects(:authorized_for?).with(crud_type: :update, column: :people).returns(true)
    assert @controller.send(:add_existing_authorized?)

    @role.expects(:authorized_for?).with(crud_type: :update, column: :people, reason: true).returns(:allowed)
    assert_equal :allowed, @controller.send(:delete_existing_authorized?)
  end

  test 'nested HABTM links are ignored outside a HABTM scaffold' do
    assert_not @controller.send(:add_existing_ignore?)
    assert_not @controller.send(:delete_existing_ignore?)

    @controller.unstub(:nested)
    @controller.stubs(:nested).returns(nil)
    assert @controller.send(:add_existing_ignore?)
    assert @controller.send(:delete_existing_ignore?)
  end

  test 'beginning of chain uses a configured nested scope' do
    parent = mock
    parent.expects(:recent).returns(:relation)
    nested = stub(match_model?: false, scope: :recent)
    @controller.stubs(:nested?).returns(true)
    @controller.stubs(:nested).returns(nested)
    @controller.stubs(:nested_parent_record).returns(parent)

    assert_equal :relation, @controller.send(:beginning_of_chain)
  end

  test 'nested chain handles belongs-to associations' do
    parent = stub(role_id: @person.id)
    association = stub(collection?: false, through?: false, has_one?: false, belongs_to?: true, name: :role_id)
    @controller.stubs(:nested).returns(stub(association: association, child_association: nil))
    @controller.stubs(:nested_parent_record).returns(parent)

    relation = @controller.send(:nested_chain_with_association)

    assert_equal [@person.id], relation.pluck(:id)
  end

  test 'nested chain handles has-one and through associations' do
    parent = Object.new
    model = mock(primary_key: 'id')
    model.expects(:where).with(owner: parent).returns(:has_one_relation)
    model.expects(:where).with('id' => @person.id).returns(:through_relation)
    @controller.stubs(:active_scaffold_config).returns(stub(model: model, mongoid?: false))
    @controller.stubs(:nested_parent_record).returns(parent)

    has_one = stub(collection?: false, through?: false, has_one?: true, belongs_to?: false)
    @controller.stubs(:nested).returns(stub(association: has_one, child_association: stub(name: :owner)))
    assert_equal :has_one_relation, @controller.send(:nested_chain_with_association)

    through = stub(collection?: false, through?: true, has_one?: false, belongs_to?: false, name: :person)
    parent.define_singleton_method(:person) { @nested_person }
    parent.instance_variable_set(:@nested_person, @person)
    @controller.stubs(:nested).returns(stub(association: through, child_association: nil))
    assert_equal :through_relation, @controller.send(:nested_chain_with_association)
  end

  test 'associates a record through singular and collection reverse associations' do
    parent = Object.new
    @controller.stubs(:nested_parent_record).returns(parent)

    singular_record = mock
    singular_record.expects(:contactable=).with(parent)
    singular_nested = stub(
      create_with_parent?: true,
      match_model?: true,
      child_association: stub(singular?: true, name: :contactable)
    )
    @controller.stubs(:nested).returns(singular_nested)
    @controller.send(:create_association_with_parent, singular_record, check_match: true)

    collection = []
    collection_record = stub(roles: collection)
    collection_nested = stub(
      create_with_parent?: true,
      match_model?: true,
      child_association: stub(singular?: false, name: :roles),
      create_through_singular?: false
    )
    @controller.stubs(:nested).returns(collection_nested)
    @controller.send(:create_association_with_parent, collection_record, check_match: true)

    assert_equal [parent], collection
  end

  private

  def assign_params(parameters)
    @controller.params = ActionController::Parameters.new(parameters)
  end
end
