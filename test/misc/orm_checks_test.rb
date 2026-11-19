# frozen_string_literal: true

require 'test_helper'

class OrmChecksTest < ActiveSupport::TestCase
  class ChecksWrapper
    include ActiveScaffold::OrmChecks

    attr_reader :active_record_class

    def initialize(active_record_class)
      @active_record_class = active_record_class
    end
  end

  def test_active_record_metadata_and_casting
    assert ActiveScaffold::OrmChecks.active_record?(Person)
    assert_not ActiveScaffold::OrmChecks.mongoid?(Person)
    assert_equal 'people', ActiveScaffold::OrmChecks.table_name(Person)
    assert_equal Person.quoted_table_name, ActiveScaffold::OrmChecks.quoted_table_name(Person)
    assert_equal Person.columns, ActiveScaffold::OrmChecks.columns(Person)
    assert_equal Person.columns_hash, ActiveScaffold::OrmChecks.columns_hash(Person)
    assert_equal Person.reflect_on_all_associations, ActiveScaffold::OrmChecks.reflect_on_all_associations(Person)
    assert_equal Person.content_columns, ActiveScaffold::OrmChecks.content_columns(Person)
    assert_equal :string, ActiveScaffold::OrmChecks.column_type(Person, :first_name)
    assert_equal Person.type_for_attribute('first_name'), ActiveScaffold::OrmChecks.type_for_attribute(Person, :first_name)
    assert_equal 12, ActiveScaffold::OrmChecks.cast(Person, :buildings_count, '12')
  end

  def test_unknown_model_metadata_has_safe_empty_defaults
    klass = Class.new

    assert_nil ActiveScaffold::OrmChecks.table_name(klass)
    assert_nil ActiveScaffold::OrmChecks.quoted_table_name(klass)
    assert_equal [], ActiveScaffold::OrmChecks.columns(klass)
    assert_equal({}, ActiveScaffold::OrmChecks.columns_hash(klass))
    assert_equal [], ActiveScaffold::OrmChecks.reflect_on_all_associations(klass)
    assert_equal [], ActiveScaffold::OrmChecks.content_columns(klass)
    assert_nil ActiveScaffold::OrmChecks.type_for_attribute(klass, :name)
    assert_nil ActiveScaffold::OrmChecks.column_type(klass, :name)
    assert_nil ActiveScaffold::OrmChecks.default_value(klass, :name)
    assert_nil ActiveScaffold::OrmChecks.cast(klass, :name, 'value')
  end

  def test_tableless_detection_and_instance_delegation
    wrapper = ChecksWrapper.new(Person)

    assert ActiveScaffold::OrmChecks.tableless?(FileModel)
    assert_predicate wrapper, :active_record?
    assert_not_predicate wrapper, :mongoid?
    assert_not_predicate wrapper, :tableless?
    assert_equal 'people', wrapper.send(:_table_name)
    assert_equal Person.columns_hash, wrapper.send(:_columns_hash)
    assert_equal :string, wrapper.column_type(:first_name)
    assert_equal 3, wrapper.cast(:buildings_count, '3')
  end

  def test_mongoid_metadata_and_casting
    mongoid = Module.new
    document = Module.new
    mongoid.const_set(:Document, document)
    Object.const_set(:Mongoid, mongoid)

    string_field = stub(type: String, default_val: 'default')
    integer_type = Class.new do
      def self.evolve(value)
        value.to_i
      end
    end
    integer_field = stub(type: integer_type, default_val: 4)
    id_field = stub
    collection = stub(name: 'documents')
    klass = Class.new do
      include Mongoid::Document

      define_singleton_method(:collection) { collection }
      define_singleton_method(:fields) { {'_id' => id_field, 'name' => string_field, 'count' => integer_field} }
      define_singleton_method(:relations) { {owner: :relation} }
    end

    assert ActiveScaffold::OrmChecks.mongoid?(klass)
    assert_equal 'documents', ActiveScaffold::OrmChecks.table_name(klass)
    assert_equal klass.fields.values, ActiveScaffold::OrmChecks.columns(klass)
    assert_equal klass.fields, ActiveScaffold::OrmChecks.columns_hash(klass)
    assert_equal [:relation], ActiveScaffold::OrmChecks.reflect_on_all_associations(klass)
    assert_equal [string_field, integer_field], ActiveScaffold::OrmChecks.content_columns(klass)
    assert_equal integer_type, ActiveScaffold::OrmChecks.column_type(klass, :count)
    assert_equal 4, ActiveScaffold::OrmChecks.default_value(klass, :count)
    assert_equal 7, ActiveScaffold::OrmChecks.cast(klass, :count, '7')
  ensure
    Object.send(:remove_const, :Mongoid) if Object.const_defined?(:Mongoid)
  end
end
