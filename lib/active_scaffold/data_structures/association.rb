module ActiveScaffold::DataStructures
  class Association
    def initialize(association, type)
      @association = association
      @type = type
    end
    attr_reader :type
    attr_writer :reverse

    def belongs_to?
      case @type
      when :active_record, :mongoid then @association.macro == :belongs_to
      when :active_mongoid
        %i(belongs_to_record belongs_to_document).include?(@association.macro)
      end
    end

    def has_one?
      case @type
      when :active_record, :mongoid then @association.macro == :has_one
      when :active_mongoid
        %i(has_one_record has_one_document).include?(@association.macro)
      end
    end

    def has_many?
      case @type
      when :active_record, :mongoid then @association.macro == :has_many
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
      when :mongoid then
        %i(has_many has_and_belongs_to_many).include?(@association.macro)
      when :active_mongoid
        %i(has_many_documents has_many_records).include?(@association.macro)
      end
    end

    def through?
      @association.options[:through].present? if @type == :active_record
    end

    # polymorphic belongs_to
    def polymorphic?
      case @type
      when :active_record then @association.polymorphic?
      when :active_mongoid, :mongoid then belongs_to? && @association.polymorphic?
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

    delegate :name, :klass, :foreign_key, :==, to: :@association

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
      when :active_mongoid, :mongoid then @association.inverse_klass
      end
    end

    def primary_key
      case @type
      when :active_record  then @association.options[:primary_key]
      when :active_mongoid, :mongoid then @association[:primary_key]
      end
    end

    def association_primary_key
      case @type
      when :active_record  then @association.association_primary_key
      when :active_mongoid, :mongoid then @association.primary_key
      end
    end

    def foreign_key
      @association.foreign_key
    end

    def foreign_type
      case @type
      when :active_record then @association.foreign_type
      when :active_mongoid, :mongoid then @association.type
      end
    end

    def counter_cache
      case @type
      when :active_record  then @association.options[:counter_cache]
      when :active_mongoid, :mongoid then @association[:counter_cache]
      end
    end

    def as
      case @type
      when :active_record  then @association.options[:as]
      when :active_mongoid, :mongoid then @association.as
      end
    end

    def dependent
      case @type
      when :active_record  then @association.options[:dependent]
      when :active_mongoid, :mongoid then @association.dependent
      end
    end

    def table_name
      case @type
      when :active_record  then @association.table_name
      when :active_mongoid, :mongoid then @association.klass.collection.name
      end
    end

    # name of inverse
    def inverse
      case @type
      when :active_record then @association.inverse_of.try(:name)
      when :active_mongoid, :mongoid then @association.inverse
      end
    end

    def reverse(klass = nil)
      unless defined? @reverse # rubocop:disable Style/IfUnlessModifier
        @reverse ||= inverse || get_reverse.try(:name)
      end
      @reverse || (get_reverse(klass).try(:name) unless klass.nil?)
    end

    def inverse_for?(klass)
      inverse_class = reverse_association(klass).try(:inverse_klass)
      inverse_class.present? && (inverse_class == klass || klass < inverse_class)
    end

    def reverse_association(klass = nil)
      return unless reverse_name = reverse(klass)
      assoc = case @type
        when :active_record, :mongoid then @association.klass.reflect_on_association(reverse_name)
        when :active_mongoid then @association.klass.reflect_on_am_association(reverse_name)
      end
      Association.new(assoc, @type) if assoc
    end

    protected

    def get_reverse(klass = nil)
      return nil if klass.nil? && polymorphic?

      # name-based matching (association name vs self.active_record.to_s)
      matches = reverse_matches(klass || self.klass)
      if matches.length > 1
        matches.select! do |assoc|
          inverse_klass.name.underscore.include? assoc.name.to_s.pluralize.singularize
        end
      end

      matches.first
    end

    def reverse_matches(klass)
      associations = case @type
        when :active_record  then klass.reflect_on_all_associations
        when :mongoid        then klass.relations.values
        when :active_mongoid then klass.am_relations.values
      end
      # collect associations that point back to this model and use the same foreign_key
      associations.each_with_object([]) do |assoc, reverse_matches|
        reverse_matches << assoc if reverse_match? assoc
      end
    end

    def reverse_match?(assoc)
      return false if assoc == @association
      return false unless assoc.polymorphic? || assoc.class_name == inverse_klass.try(:name)

      if through?
        reverse_through_match?(assoc) if assoc.options[:through]
      elsif habtm?
        reverse_habtm_match?(assoc) if assoc.macro == :has_and_belongs_to_many
      else
        reverse_direct_match?(assoc)
      end
    end

    def reverse_through_match?(assoc)
      assoc.through_reflection.class_name == through_reflection.class_name
    end

    def reverse_habtm_match?(assoc)
      assoc.options[:join_table] == @association.options[:join_table]
    end

    def reverse_direct_match?(assoc)
      # skip over has_many :through associations
      return false if @type == :active_record && assoc.options[:through]
      # skip over has_and_belongs_to_many associations
      return false if assoc.macro == :has_and_belongs_to_many

      if assoc.foreign_key.is_a? Array # composite_primary_keys
        assoc.foreign_key == foreign_key
      else
        assoc.foreign_key.to_sym == foreign_key.to_sym
      end
    end
  end
end
