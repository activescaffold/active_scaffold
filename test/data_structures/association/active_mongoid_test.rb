# frozen_string_literal: true

require 'test_helper'

class ActiveMongoidAssociationTest < ActiveSupport::TestCase
  test 'lists ActiveMongoid relations only for supporting models' do
    model = stub(am_relations: {owner: :owner_reflection, tags: :tags_reflection})

    assert_equal %i[owner_reflection tags_reflection], described_class.reflect_on_all_associations(model)
    assert_empty described_class.reflect_on_all_associations(Object.new)
  end

  test 'looks up reverse ActiveMongoid relations on the associated class' do
    model = mock
    model.expects(:reflect_on_am_association).with(:owner).returns(:owner_reflection)
    association = described_class.new(base_reflection(:has_many_documents, klass: model))

    assert_equal :owner_reflection, association.send(:reflect_on_association, :owner)
  end

  test 'maps ActiveMongoid macros and metadata' do
    reflection = stub(
      macro: :belongs_to_record,
      klass: String,
      foreign_key: :record_id,
      options: {},
      name: :record,
      as: nil
    )
    reflection.stubs(:[]).with(:primary_key).returns(:uuid)
    reflection.stubs(:[]).with(:counter_cache).returns(:records_count)
    association = described_class.new(reflection)

    assert_predicate association, :belongs_to?
    assert_not_predicate association, :has_one?
    assert_not_predicate association, :has_many?
    assert_equal :uuid, association.primary_key
    assert_equal :records_count, association.counter_cache
    assert_not_predicate association, :allow_join?
  end

  test 'recognizes document and collection macros' do
    assert_predicate adapter(:has_one_document), :has_one?
    assert_predicate adapter(:has_many_records), :has_many?
  end

  test 'uses inverse class name for polymorphic ActiveMongoid relations' do
    reflection = base_reflection(:belongs_to_document)
    reflection.stubs(as: :attachable)
    reflection.stubs(:[]).with(:inverse_class_name).returns('String')

    assert_equal String, described_class.new(reflection).inverse_klass
  end

  test 'uses Active Record table names and Mongoid collection names' do
    active_record_reflection = base_reflection(:has_many_records, klass: Person)
    collection = stub(name: 'documents')
    mongoid_model = Class.new
    mongoid_model.define_singleton_method(:collection) { collection }
    mongoid_reflection = base_reflection(:has_many_documents, klass: mongoid_model)

    assert_equal 'people', described_class.new(active_record_reflection).table_name
    assert_equal 'documents', described_class.new(mongoid_reflection).table_name
  end

  private

  def described_class
    ActiveScaffold::DataStructures::Association::ActiveMongoid
  end

  def adapter(macro)
    described_class.new(base_reflection(macro))
  end

  def base_reflection(macro, klass: String)
    stub(
      macro: macro,
      klass: klass,
      foreign_key: :record_id,
      options: {},
      name: :record,
      as: nil
    )
  end
end
