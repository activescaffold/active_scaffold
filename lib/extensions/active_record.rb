class ActiveRecord::Base

  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to?(attribute) and send(attribute).is_a?(String)
    end
  end

  def associated_valid?
    with_instantiated_associated {|a| a.valid? and a.associated_valid?}
  end
  
  def instantiated_for_edit
    @instantiated_for_edit = true
  end
  
  def instantiated_for_edit?
    @instantiated_for_edit
  end

  def no_errors_in_associated?
    with_instantiated_associated {|a| a.errors.count == 0 and a.no_errors_in_associated?}
  end

  # To prevent the risk of a circular association we track which objects
  # have been saved already. We use a [class,id] tuple because find will
  # return different object references for the same record.
  def save_associated( save_list = [] )
    with_instantiated_associated do |a|
      if save_list.include?( [a.class,a.id] )
        true
      else
        a.save and a.save_associated( save_list << [a.class,a.id] )
      end
    end
  end

  def save_associated!
    self.save_associated || raise(ActiveRecord::RecordNotSaved)
  end

  private
  
  # Provide an override to allow the model to restrict which associations are considered
  # by ActiveScaffolds update mechanism. This allows the model to restrict things like
  # Acts-As-Versioned versions associations being traversed.
  #
  # By defining the method :scaffold_update_nofollow returning an array of associations
  # these associations will not be traversed.
  # By defining the method :scaffold_update_follow returning an array of associations, 
  # only those associations will be traversed.
  #
  # Otherwise the default behaviour of traversing all associations will be preserved.
  def associations_for_update
    if self.respond_to?( :scaffold_update_nofollow )
      self.class.reflect_on_all_associations.reject { |association| self.scaffold_update_nofollow.include?( association.name ) }
    elsif self.respond_to?( :scaffold_update_follow )
      self.class.reflect_on_all_associations.select { |association| self.scaffold_update_follow.include?( association.name ) }
    else
      self.class.reflect_on_all_associations
    end
  end
  
  # yields every associated object that has been instantiated (and therefore possibly changed).
  # returns true if all yields return true. returns false otherwise.
  # returns true by default, e.g. when none of the associations have been instantiated. build accordingly.
  def with_instantiated_associated
    associations_for_update.all? do |association|
      association_proxy = instance_variable_get("@#{association.name}")
      if association_proxy && association_proxy.target && !( association_proxy.class == self.class && association_proxy.id == self.id )
        case association.macro
          when :belongs_to, :has_one
          yield association_proxy unless association_proxy.readonly?

          when :has_many, :has_and_belongs_to_many
          association_proxy.select {|r| not r.readonly?}.all? {|r| yield r}
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
            next unless assoc.options[:polymorphic] or assoc.class_name.constantize == self.active_record
            case [assoc.macro, self.macro].find_all{|m| m == :has_and_belongs_to_many}.length
              # if both are a habtm, then match them based on the join table
              when 2
              next unless assoc.options[:join_table] == self.options[:join_table]

              # if only one is a habtm, they do not match
              when 1
              next

              # otherwise, match them based on the primary_key_name
              when 0
              next unless assoc.primary_key_name.to_sym == self.primary_key_name.to_sym
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