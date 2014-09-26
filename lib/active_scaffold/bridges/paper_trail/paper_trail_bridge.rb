module ActiveScaffold
  module Bridges
    class PaperTrail
      module PaperTrailBridge
        def initialize_with_paper_trail(model_id)
          initialize_without_paper_trail(model_id)
          return unless self.model < ::PaperTrail::Model::InstanceMethods
          self.actions << :deleted_records
        end
        
        def self.included(base)
          base.alias_method_chain :initialize, :paper_trail
        end
      end
    end
  end
end
