# frozen_string_literal: true

class ActiveScaffold::Bridges::SemanticAttributes
  module Column
    def initialize(name, active_record_class)
      super
      self.required = !active_record_class.semantic_attributes[self.name].predicates.find { |p| p.allow_empty? == false }.nil?
      ignored_types = %i[required association]
      active_record_class.semantic_attributes[self.name].predicates.find do |p|
        sem_type = p.class.to_s.split('::')[1].underscore.to_sym
        next if ignored_types.include?(sem_type)

        @form_ui = sem_type
      end
    end
  end
end
ActiveScaffold::DataStructures::Column.class_eval do
  prepend ActiveScaffold::Bridges::SemanticAttributes::Column
end
