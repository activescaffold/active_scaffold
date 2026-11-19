# frozen_string_literal: true

require 'test_helper'

class MongoidAssociationTest < ActiveSupport::TestCase
  setup do
    @original_mongoid = Object.const_get(:Mongoid) if Object.const_defined?(:Mongoid)
    Object.send(:remove_const, :Mongoid) if Object.const_defined?(:Mongoid)

    mongoid = Module.new
    association = Module.new
    @belongs_to_class = Class.new
    @has_one_class = Class.new
    @has_many_class = Class.new
    @habtm_class = Class.new
    association.const_set(
      :MACRO_MAPPING,
      {
        belongs_to: @belongs_to_class,
        has_one: @has_one_class,
        has_many: @has_many_class,
        has_and_belongs_to_many: @habtm_class
      }
    )
    mongoid.const_set(:Association, association)
    Object.const_set(:Mongoid, mongoid)
  end

  teardown do
    Object.send(:remove_const, :Mongoid) if Object.const_defined?(:Mongoid)
    Object.const_set(:Mongoid, @original_mongoid) if @original_mongoid
  end

  test 'maps Mongoid reflection classes to association predicates' do
    assert_predicate adapter(@belongs_to_class), :belongs_to?
    assert_predicate adapter(@has_one_class), :has_one?
    assert_predicate adapter(@has_many_class), :has_many?
    assert_predicate adapter(@habtm_class), :habtm?
    assert_predicate adapter(@has_many_class), :collection?
  end

  test 'exposes Mongoid reflection metadata without a database connection' do
    model = stub(collection: stub(name: 'articles'))
    reflection = reflection(@belongs_to_class, klass: model)
    reflection.stubs(
      polymorphic?: true,
      primary_key: :uuid,
      type: :owner_type,
      inverse_klass: String,
      as: :owner,
      dependent: :destroy,
      inverse: :articles
    )
    association = described_class.new(reflection)

    assert_predicate association, :polymorphic?
    assert_equal :uuid, association.association_primary_key
    assert_equal :owner_type, association.foreign_type
    assert_equal 'articles', association.table_name
    assert_equal 'articles', association.quoted_table_name
    assert_equal '_id', association.quoted_primary_key
    assert_equal String, association.inverse_klass
    assert_equal :owner, association.as
    assert_equal :destroy, association.dependent
    assert_equal :articles, association.inverse
  end

  test 'lists relations from a Mongoid model' do
    model = stub(relations: {owner: :owner_reflection, tags: :tags_reflection})

    assert_equal %i[owner_reflection tags_reflection], described_class.reflect_on_all_associations(model)
  end

  private

  def described_class
    ActiveScaffold::DataStructures::Association::Mongoid
  end

  def adapter(reflection_class)
    described_class.new(reflection(reflection_class))
  end

  def reflection(reflection_class, klass: stub)
    reflection_class.new.tap do |value|
      value.stubs(macro: :unused, klass: klass, foreign_key: :owner_id, options: {}, name: :owner)
    end
  end
end
