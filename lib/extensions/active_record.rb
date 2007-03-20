class ActiveRecord::Base

  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to? attribute
    end
  end

  def associated_valid?
    with_instantiated_associated {|a| a.valid? and a.associated_valid?}
  end

  def save_associated
    with_instantiated_associated {|a| a.save and a.save_associated}
  end

  def save_associated!
    self.save_associated || raise(RecordNotSaved)
  end

  private

  # yields every associated object that has been instantiated (and therefore possibly changed).
  # returns true if all yields return true. returns false otherwise.
  def with_instantiated_associated
    self.class.reflect_on_all_associations.all? do |association|
      if associated = instance_variable_get("@#{association.name}")
        case association.macro
          when :belongs_to, :has_one
          yield associated

          when :has_many, :has_and_belongs_to_many
          associated.all? {|r| yield r}
        end
      else
        true
      end
    end
  end
end

module ActiveRecord
  module Reflection
    class AssociationReflection #:nodoc:
      attr_writer :reverse
      def reverse
        unless @reverse
          reverse_matches = []
          # stage 1 filter: collect associations that point back to this model and use the same primary_key_name
          self.class_name.constantize.reflect_on_all_associations.each do |assoc|
            next unless assoc.class_name.constantize == self.active_record
            case [assoc.macro, self.macro].find_all{|m| m == :has_and_belongs_to_many}.length
              # if both are a habtm, then match them based on the join table
              when 2
              next unless assoc.options[:join_table] == self.options[:join_table]

              # if only one is a habtm, they do not match
              when 1
              next

              # otherwise, match them based on the primary_key_name
              when 0
              next unless assoc.primary_key_name == self.primary_key_name
            end

            reverse_matches << assoc
          end

          # stage 2 filter: name-based matching (association name vs self.active_record.to_s)
          reverse_matches.find_all do |assoc|
            self.active_record.to_s.underscore.include? assoc.name.to_s.pluralize.singularize
          end if reverse_matches.length > 1

          # stage 3 filter: grab first association, or make a wild guess
          @reverse = reverse_matches.empty? ? self.active_record.to_s.pluralize.underscore : reverse_matches.first.name
        end
        @reverse
      end
    end
  end
end