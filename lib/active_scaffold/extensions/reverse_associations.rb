module ActiveScaffold
  module ReverseAssociation
    module CommonMethods
      def self.included(base)
        base.class_eval { attr_writer :reverse }
        base.alias_method_chain :inverse_of, :autodetect
      end

      def inverse_of_with_autodetect
        inverse_of_without_autodetect || autodetect_inverse
      end

      def inverse_for?(klass)
        inverse_class = inverse_of.try(:active_record)
        inverse_class.present? && (inverse_class == klass || klass < inverse_class)
      end

      def reverse(klass = nil)
        unless defined? @reverse # rubocop:disable Style/IfUnlessModifier
          @reverse ||= inverse_of.try(:name)
        end
        @reverse || (autodetect_inverse(klass).try(:name) unless klass.nil?)
      end

      def autodetect_inverse(klass = nil)
        return nil if klass.nil? && options[:polymorphic]
        klass ||= self.klass

        # name-based matching (association name vs self.active_record.to_s)
        matches = reverse_matches(klass)
        if matches.length > 1
          matches.find_all do |assoc|
            active_record.to_s.underscore.include? assoc.name.to_s.pluralize.singularize
          end
        end

        matches.first
      end
    end

    module AssociationReflection
      def self.included(base)
        base.send :include, ActiveScaffold::ReverseAssociation::CommonMethods
      end

      protected

      def reverse_matches(klass)
        reverse_matches = []

        # collect associations that point back to this model and use the same foreign_key
        klass.reflect_on_all_associations.each do |assoc|
          next if assoc == self
          # skip over has_many :through associations
          next if assoc.options[:through]
          next unless assoc.options[:polymorphic] || assoc.class_name == active_record.name

          case [assoc.macro, macro].find_all { |m| m == :has_and_belongs_to_many }.length
            # if both are a habtm, then match them based on the join table
            when 2
              next unless assoc.options[:join_table] == options[:join_table]

            # if only one is a habtm, they do not match
            when 1
              next

            # otherwise, match them based on the foreign_key
            when 0
              if assoc.foreign_key.is_a? Array
                next unless assoc.foreign_key == foreign_key
              else
                next unless assoc.foreign_key.to_sym == foreign_key.to_sym
              end
          end

          reverse_matches << assoc
        end
        reverse_matches
      end
    end

    module ThroughReflection
      def self.included(base)
        base.send :include, ActiveScaffold::ReverseAssociation::CommonMethods unless base < ActiveScaffold::ReverseAssociation::CommonMethods
      end

      protected

      def reverse_matches(klass)
        reverse_matches = []

        # collect associations that point back to this model and use the same foreign_key
        klass.reflect_on_all_associations.each do |assoc|
          next if assoc == self
          # only iterate has_many :through associations
          next unless assoc.options[:through]
          next unless assoc.class_name == active_record.name
          next unless assoc.through_reflection.class_name == through_reflection.class_name

          reverse_matches << assoc
        end
        reverse_matches
      end
    end

    module ThroughAssociation
      # NOTE - for now, we're only supporting inverse setting back onto has_one associations.
      # TODO remove when rails fixes this and old versions are not supported
      def invertible_for?(record)
        inverse = super
        inverse && !inverse.collection?
      end
    end
  end
end

ActiveRecord::Reflection::AssociationReflection.send :include, ActiveScaffold::ReverseAssociation::AssociationReflection
ActiveRecord::Reflection::ThroughReflection.send :include, ActiveScaffold::ReverseAssociation::ThroughReflection
ActiveRecord::Associations::ThroughAssociation.send :include, ActiveScaffold::ReverseAssociation::ThroughAssociation
