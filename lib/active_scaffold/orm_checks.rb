module ActiveScaffold
  module OrmChecks
    def active_record?(model = self.active_record_class)
      return unless defined? ActiveRecord
      model < ActiveRecord::Base
    end

    def mongoid?(model = self.active_record_class)
      return unless defined? Mongoid
      model < Mongoid::Document
    end

    def tableless?(model = self.active_record_class)
      model < ActiveScaffold::Tableless
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
