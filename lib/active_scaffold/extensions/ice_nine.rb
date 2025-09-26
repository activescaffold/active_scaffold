# frozen_string_literal: true

module IceNine
  class Freezer
    def self.find(name)
      freezer = name.split('::').reduce(self) do |mod, const|
        mod.const_lookup(const) or break mod
      end
      freezer if freezer < self # only return a descendant freezer
    end

    class ObjectWithExclussion < Object
      class_attribute :excluded_vars
      self.excluded_vars = []
      def self.freeze_instance_variables(object, recursion_guard)
        object.instance_variables.each do |ivar_name|
          next if excluded_vars.include? ivar_name

          Freezer.guarded_deep_freeze(
            object.instance_variable_get(ivar_name),
            recursion_guard
          )
        end
      end
      private_class_method :freeze_instance_variables
    end

    class ActiveScaffold < ::IceNine::Freezer::Object
      class DataStructures < ::IceNine::Freezer::Object
        class Column < ::IceNine::Freezer::ObjectWithExclussion
          self.excluded_vars = %i[@active_record_class @column]
        end

        class Association < ::IceNine::Freezer::NoFreeze
        end
      end
    end
  end
end
