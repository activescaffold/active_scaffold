# frozen_string_literal: true

class ModelStub < ActiveRecord::Base
  validates :b, presence: true
  has_one :other_model, class_name: 'ModelStub' # rubocop:disable Rails/DuplicateAssociation
  has_many :other_models, class_name: 'ModelStub' # rubocop:disable Rails/DuplicateAssociation

  cattr_accessor :stubbed_columns
  self.stubbed_columns = %i[a b c d id created_at]
  attr_accessor(*stubbed_columns)

  self.primary_key = :id

  @@nested_scope_calls = []
  cattr_accessor :nested_scope_calls

  def self.schema_loaded? = true

  def self.a_is_defined
    @@nested_scope_calls << :a_is_defined
    self
  end

  def self.b_like(pattern)
    @@nested_scope_calls << :b_like
    self
  end

  attr_writer :other_model, :other_models

  def other_model
    @other_model || nil
  end

  def other_models
    @other_models || []
  end

  def self.columns
    @columns ||= stubbed_columns.map do |c|
      column = ColumnMock.new(c.to_s, '', 'varchar(255)')
      column.primary = true if c.to_s == primary_key.to_s && column.respond_to?(:primary=)
      column
    end
  end

  def self.columns_hash
    @columns_hash ||= columns.index_by { |column| column.name.to_s }
  end

  if respond_to? :type_for_attribute
    def self.type_for_attribute(attribute_name)
      defined?(ActiveModel::Type) ? ActiveModel::Type::String.new : super
    end
  end

  # column-level security methods, used for testing
  def self.a_authorized_for_bar?
    true
  end

  def self.b_authorized?
    false
  end

  def self.c_authorized_for_create?
    false
  end
end
