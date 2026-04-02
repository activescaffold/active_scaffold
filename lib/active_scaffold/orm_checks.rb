# frozen_string_literal: true

module ActiveScaffold
  module OrmChecks
    class << self
      def active_record?(klass)
        return false unless defined? ActiveRecord

        klass < ActiveRecord::Base
      end

      def mongoid?(klass)
        return false unless defined? Mongoid

        klass < Mongoid::Document
      end

      def tableless?(klass)
        klass < ActiveScaffold::Tableless
      end

      def table_name(klass)
        if active_record? klass
          klass.table_name
        elsif mongoid? klass
          klass.collection.name
        end
      end

      def quoted_table_name(klass)
        klass.quoted_table_name if active_record? klass
      end

      def columns(klass)
        if active_record? klass
          klass.columns
        elsif mongoid? klass
          klass.fields.values
        else
          []
        end
      end

      def columns_hash(klass)
        if active_record? klass
          klass.columns_hash
        elsif mongoid? klass
          klass.fields
        else
          {}
        end
      end

      def reflect_on_all_associations(klass)
        if active_record? klass
          klass.reflect_on_all_associations
        elsif mongoid? klass
          klass.relations.values
        else
          []
        end
      end

      def content_columns(klass)
        if active_record? klass
          klass.content_columns
        elsif mongoid? klass
          klass.fields.except('_id').values
        else
          []
        end
      end

      def type_for_attribute(klass, column_name)
        if active_record? klass
          klass.type_for_attribute column_name.to_s
        elsif mongoid? klass
          klass.fields[column_name.to_s]&.type
        end
      end

      def column_type(klass, column_name)
        if active_record? klass
          type_for_attribute(klass, column_name).type
        elsif mongoid? klass
          type_for_attribute(klass, column_name)
        end
      end

      def default_value(klass, column_name)
        if ActiveScaffold::OrmChecks.mongoid? klass
          columns_hash(klass)[column_name.to_s]&.default_val
        elsif ActiveScaffold::OrmChecks.active_record? klass
          klass._default_attributes[column_name.to_s]&.value
        end
      end

      def cast(klass, column_name, value)
        if active_record? klass
          type_for_attribute(klass, column_name).cast value
        elsif mongoid? klass
          type_for_attribute(klass, column_name)&.evolve value
        end
      end
    end

    %i[active_record? mongoid? tableless?].each do |method|
      define_method method do
        ActiveScaffold::OrmChecks.send method, active_record_class
      end
    end

    %i[_table_name _quoted_table_name _columns _columns_hash _reflect_on_all_associations _content_columns].each do |method|
      define_method method do
        ActiveScaffold::OrmChecks.send method.to_s[1..], active_record_class
      end
    end

    %i[type_for_attribute column_type default_value].each do |method|
      define_method method do |column_name|
        ActiveScaffold::OrmChecks.send method, active_record_class, column_name
      end
    end

    def cast(column_name, value)
      ActiveScaffold::OrmChecks.cast active_record_class, column_name, value
    end
  end
end
