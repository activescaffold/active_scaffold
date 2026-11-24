# frozen_string_literal: true

module ActiveScaffold
  class ApiAssociationSerializer
    def initialize(columns = nil)
      @columns = columns
    end

    def serialize(value, column)
      if column.association.collection?
        value.filter_map { |record| serialize_record(record, column) }
      else
        serialize_record(value, column)
      end
    end

    private

    def serialize_record(record, column)
      return unless record && readable?(record)

      columns = @columns ? @columns.call(column, record) : [record.class.primary_key, :to_label]
      columns = Array(columns).compact.map(&:to_s).select { |name| readable?(record, column: name.to_sym) }
      attributes, methods = columns.partition { |name| record.has_attribute?(name) }
      record.serializable_hash(only: attributes, methods: methods, include: [])
    end

    def readable?(record, **options)
      !record.respond_to?(:authorized_for?) || record.authorized_for?(crud_type: :read, **options)
    end
  end
end
