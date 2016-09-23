module ActiveScaffold::DataStructures::Association
  class ActiveRecord < Abstract
    delegate :collection?, :polymorphic?, :association_primary_key, :foreign_type, :table_name, to: :@association

    def through?
      @association.options[:through].present?
    end

    def readonly?
      scope_values[:readonly]
    end

    def through_reflection
      @association.through_reflection if through?
    end

    def source_reflection
      @association.source_reflection if through?
    end

    def scope
      @association.scope
    end

    def inverse_klass
      @association.active_record
    end

    def primary_key
      @association.options[:primary_key]
    end

    def counter_cache
      @association.options[:counter_cache]
    end

    def as
      @association.options[:as]
    end

    def dependent
      @association.options[:dependent]
    end

    # name of inverse
    def inverse
      @association.inverse_of.try(:name)
    end

    def quoted_table_name
      @association.klass.quoted_table_name
    end
    
    def quoted_primary_key
      @association.klass.quoted_primary_key
    end
    
    def respond_to_target?
      false
    end
    
    def counter_cache_hack?
      if has_many?
        Rails.version < '5.0' && as
      elsif belongs_to?
        counter_cache && (Rails.version >= '5.0' || !polymorphic?)
      end
    end
    
    protected
    def scope_values
      return {} unless @association.scope
      @scope_values ||= @association.klass.instance_exec(&@association.scope).values rescue {}
    end

    def reverse_through_match?(assoc)
      assoc.options[:through] && assoc.through_reflection.class_name == through_reflection.class_name
    end

    def reverse_habtm_match?(assoc)
      super && assoc.options[:join_table] == @association.options[:join_table]
    end

    def reverse_direct_match?(assoc)
      # skip over has_many :through associations
      !assoc.options[:through] && super
    end
    
    def self.reflect_on_all_associations(klass)
      klass.reflect_on_all_associations
    end
  end
end
