# frozen_string_literal: true

module ActiveScaffold
  class ApiAssociationSerializer
    def initialize(options = nil)
      @options = options
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
      return unless record
      return if record.respond_to?(:authorized_for?) && !record.authorized_for?(crud_type: :read)

      options = @options ? @options.call(column, record) : {only: [record.class.primary_key], methods: [:to_label]}
      record.serializable_hash(options)
    end
  end
end
