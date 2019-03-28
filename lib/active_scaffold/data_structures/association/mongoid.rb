module ActiveScaffold::DataStructures::Association
  class Mongoid < Abstract
    delegate :inverse_klass, :as, :dependent, :inverse, to: :@association

    # polymorphic belongs_to
    def polymorphic?
      belongs_to? && @association.polymorphic?
    end

    def primary_key
      @association[:primary_key]
    end

    def association_primary_key
      @association.primary_key
    end

    def foreign_type
      @association.type
    end

    def counter_cache
      @association[:counter_cache]
    end

    def table_name
      @association.klass.collection.name
    end

    def quoted_table_name
      table_name
    end

    def quoted_primary_key
      '_id'
    end

    def self.reflect_on_all_associations(klass)
      klass.relations.values
    end
  end
end
