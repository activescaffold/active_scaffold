module ActiveScaffold
  module OrmChecks
    def active_record?
      active_record_class < ActiveRecord::Base
    end

    def mongoid?
      active_record_class < Mongoid::Document
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
        active_record_class.columns.reject { |c| c.name == '_id' }
      else
        []
      end
    end
  end
end
