module ActiveScaffold
  module OrmChecks
    def active_record?
      return unless defined? ActiveRecord
      active_record_class < ActiveRecord::Base
    end

    def mongoid?
      return unless defined? Mongoid
      active_record_class < Mongoid::Document
    end

    def tableless?
      active_record_class < ActiveScaffold::Tableless
    end

    def _table_name
      if active_record?
        active_record_class.table_name
      elsif mongoid?
        active_record_class.collection.name
      end
    end

    def _quoted_table_name
      active_record_class.quoted_table_name if active_record?
    end

    def _columns
      if active_record?
        active_record_class.columns
      elsif mongoid?
        active_record_class.fields.values
      else
        []
      end
    end

    def _columns_hash
      if active_record?
        active_record_class.columns_hash
      elsif mongoid?
        active_record_class.fields
      else
        []
      end
    end

    def _reflect_on_all_associations
      if active_record?
        reflect_on_all_associations
      elsif mongoid?
        relations.values
      end
    end

    def _content_columns
      if active_record?
        active_record_class.content_columns
      elsif mongoid?
        active_record_class.fields.reject { |field, _| field == '_id' }.values
      else
        []
      end
    end
  end
end
