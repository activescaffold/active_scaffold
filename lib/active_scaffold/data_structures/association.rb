module ActiveScaffold::DataStructures
  class Association
    def initialize(association, type)
      @association = association
      @type = type
    end
    attr_reader :type

    def belongs_to?
      case @type
      when :active_record then @association.macro == :belongs_to
      when :active_mongoid
        %i(belongs_to_record belongs_to_document).include?(@association.macro)
      end
    end

    def has_one?
      case @type
      when :active_record then @association.macro == :has_one
      when :active_mongoid
        %i(has_one_record has_one_document).include?(@association.macro)
      end
    end

    def has_many?
      case @type
      when :active_record then @association.macro == :has_many
      when :active_mongoid
        %i(has_many_records has_many_documents).include?(@association.macro)
      end
    end

    def habtm?
      @association.macro == :has_and_belongs_to_many
    end

    def singular?
      !collection?
    end

    def collection?
      case @type
      when :active_record then @association.collection?
      when :active_mongoid
        %i(has_many_documents has_many_records).include?(@association.macro)
      end
    end

    def through?
      @association.options[:through] if @type == :active_record
    end

    def polymorphic?
      case @type
      when :active_record  then @association.polymorphic?
      when :active_mongoid then belongs_to? && @association.polymorphic?
      end
    end

    def readonly?
      return false unless @type == :active_record
      if @association.options.key? :readonly
        @association.options[:readonly]
      else
        through?
      end
    end

    delegate :name, :klass, :foreign_key, to: :@association

    def through_reflection
      @association.through_reflection if through?
    end

    def source_reflection
      @association.source_reflection if through?
    end

    def scope
      @association.scope if @type == :active_record
    end

    def inverse_klass
      case @type
      when :active_record  then @association.active_record
      when :active_mongoid then @association.inverse_klass
      end
    end

    def primary_key
      case @type
      when :active_record  then @association.options[:primary_key]
      when :active_mongoid then @association[:primary_key]
      end
    end

    def association_primary_key
      case @type
      when :active_record  then @association.association_primary_key
      when :active_mongoid then @association.primary_key
      end
    end

    def foreign_key
      @association.foreign_key
    end

    def foreign_type
      case @type
      when :active_record  then @association.foreign_type
      when :active_mongoid then @association.type
      end
    end

    def counter_cache
      case @type
      when :active_record  then @association.options[:counter_cache]
      when :active_mongoid then @association[:counter_cache]
      end
    end

    def as
      case @type
      when :active_record  then @association.options[:as]
      when :active_mongoid then @association.as
      end
    end

    def dependent
      case @type
      when :active_record  then @association.options[:dependent]
      when :active_mongoid then @association.dependent
      end
    end

    def table_name
      case @type
      when :active_record  then @association.table_name
      when :active_mongoid then @association.klass.collection.name
      end
    end

    def reverse(klass = nil)
      # FIXME move reverse_association extension code here
      @association.reverse(klass) if @type == :active_record
    end

    def inverse_for?(klass)
      # FIXME move reverse_association extension code here
      @association.inverse_for?(klass) if @type == :active_record
    end

    def reverse_association
      return unless reverse_name = reverse
      assoc = case @type
        when :active_record  then @association.klass.reflect_on_association(reverse_name)
        when :active_mongoid then @association.klass.reflect_on_am_association(reverse_name)
      end
      Association.new(assoc, @type) if assoc
    end
  end
end
