# frozen_string_literal: true

module ActiveScaffold::DataStructures::Association
  class Mongoid < Abstract
    delegate :inverse_klass, :as, :dependent, :inverse, to: :@association

    def belongs_to?
      # once Ruby 2.6 support is dropped, use macro_mapping? always
      defined?(::Mongoid::Association) ? macro_mapping?(:belongs_to) : super
    end

    def has_one? # rubocop:disable Naming/PredicatePrefix
      defined?(::Mongoid::Association) ? macro_mapping?(:has_one) : super
    end

    def has_many? # rubocop:disable Naming/PredicatePrefix
      defined?(::Mongoid::Association) ? macro_mapping?(:has_many) : super
    end

    def habtm?
      defined?(::Mongoid::Association) ? macro_mapping?(:has_and_belongs_to_many) : super
    end

    # polymorphic belongs_to
    def polymorphic?
      belongs_to? && @association.polymorphic?
    end

    def association_primary_key
      @association.primary_key
    end

    def foreign_type
      @association.type
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

    def macro_mapping?(macro)
      @association.is_a? ::Mongoid::Association::MACRO_MAPPING[macro]
    end
  end
end
