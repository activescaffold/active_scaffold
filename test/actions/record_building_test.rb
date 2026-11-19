# frozen_string_literal: true

require 'test_helper'

class RecordBuildingActionTest < ActionController::TestCase
  tests PeopleController

  test 'builds STI options from a top-level inheritance parameter' do
    klass = stub(inheritance_column: 'type')
    config = stub(_columns_hash: {'type' => Object.new})
    @controller.stubs(:active_scaffold_config_for).with(klass).returns(config)
    @controller.params = ActionController::Parameters.new(type: 'special_person')

    options = @controller.send(:sti_nested_build_options, klass)

    assert_equal({type: 'SpecialPerson'}, options)
    assert_not @controller.params.key?(:type)
  end

  test 'builds STI options from a create-record parameter' do
    klass = stub(inheritance_column: 'type')
    config = stub(_columns_hash: {'type' => Object.new})
    @controller.stubs(:active_scaffold_config_for).with(klass).returns(config)
    @controller.params = ActionController::Parameters.new(record: {type: 'special_person'})

    options = @controller.send(:sti_nested_build_options, klass)

    assert_equal({type: 'SpecialPerson'}, options)
    assert_not @controller.params[:record].key?(:type)
  end

  test 'defaults STI options to the configured model name' do
    klass = stub(inheritance_column: 'type')
    config = stub(_columns_hash: {'type' => Object.new})
    @controller.stubs(:active_scaffold_config_for).with(klass).returns(config)
    @controller.params = ActionController::Parameters.new

    assert_equal({type: 'Person'}, @controller.send(:sti_nested_build_options, klass))
  end

  test 'does not build STI options without a scaffold configuration' do
    klass = stub(inheritance_column: 'type')
    @controller.stubs(:active_scaffold_config_for).with(klass).returns(nil)

    assert_nil @controller.send(:sti_nested_build_options, klass)
  end

  test 'creates a through record for collection and singular reverse associations' do
    through = Object.new
    parent = mock
    parent.stubs(:membership).returns(nil)
    parent.stubs(:build_membership).returns(through)

    collection = []
    collection_record = stub(rates: collection)
    collection_source = stub(reverse_association: stub(collection?: true), reverse: :rates)
    collection_association = stub(through_reflection: stub(name: :membership), source_reflection: collection_source)
    @controller.send(:create_on_through_singular, collection_record, collection_association, parent)
    assert_equal [through], collection

    singular_record = mock
    singular_record.expects(:rate=).with(through)
    singular_source = stub(reverse_association: stub(collection?: false), reverse: :rate)
    singular_association = stub(through_reflection: stub(name: :membership), source_reflection: singular_source)
    @controller.send(:create_on_through_singular, singular_record, singular_association, parent)
  end
end
