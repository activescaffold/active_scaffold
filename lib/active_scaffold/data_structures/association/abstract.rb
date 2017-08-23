module ActiveScaffold::DataStructures::Association
  class Abstract
    def initialize(association)
      @association = association
    end
    attr_writer :reverse
    delegate :name, :klass, :foreign_key, :==, to: :@association

    def allow_join?
      !polymorphic?
    end

    def belongs_to?
      @association.macro == :belongs_to
    end

    def has_one?
      @association.macro == :has_one
    end

    def has_many?
      @association.macro == :has_many
    end

    def habtm?
      @association.macro == :has_and_belongs_to_many
    end

    def singular?
      !collection?
    end

    def through?
      false
    end

    def polymorphic?
      false
    end

    def readonly?
      false
    end

    def through_reflection; end

    def source_reflection; end

    def scope; end

    def respond_to_target?
      false
    end

    def counter_cache_hack?
      false
    end

    def quoted_table_name
      raise "define quoted_table_name method in #{self.class.name} class"
    end

    def quoted_primary_key
      raise "define quoted_primary_key method in #{self.class.name} class"
    end

    def reverse(klass = nil)
      unless polymorphic? || defined?(@reverse)
        @reverse ||= inverse || get_reverse.try(:name)
      end
      @reverse || (get_reverse(klass).try(:name) unless klass.nil?)
    end

    def inverse_for?(klass)
      inverse_class = reverse_association(klass).try(:inverse_klass)
      inverse_class.present? && (inverse_class == klass || klass < inverse_class)
    end

    def reverse_association(klass = nil)
      assoc = if polymorphic?
                get_reverse(klass) unless klass.nil?
              else
                return unless reverse_name = reverse(klass)
                reflect_on_association(reverse_name)
      end
      self.class.new(assoc) if assoc
    end

    protected

    def reflect_on_association(name)
      @association.klass.reflect_on_association(name)
    end

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
      associations = self.class.reflect_on_all_associations(klass)
      # collect associations that point back to this model and use the same foreign_key
      associations.each_with_object([]) do |assoc, reverse_matches|
        reverse_matches << assoc if reverse_match? assoc
      end
    end

    def reverse_match?(assoc)
      return false if assoc == @association
      return false unless assoc.polymorphic? || assoc.class_name == inverse_klass.try(:name)

      if through?
        reverse_through_match?(assoc)
      elsif habtm?
        reverse_habtm_match?(assoc)
      else
        reverse_direct_match?(assoc)
      end
    end

    def reverse_through_match?(assoc); end

    def reverse_habtm_match?(assoc)
      assoc.macro == :has_and_belongs_to_many
    end

    def reverse_direct_match?(assoc)
      # skip over has_and_belongs_to_many associations
      return false if assoc.macro == :has_and_belongs_to_many

      if foreign_key.is_a?(Array) || assoc.foreign_key.is_a?(Array) # composite_primary_keys
        assoc.foreign_key == foreign_key
      else
        assoc.foreign_key.to_sym == foreign_key.to_sym
      end
    end
  end
end
