# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class PaperTrail
      module PaperTrailBridge
        def initialize(model_id)
          super
          return unless model < ::PaperTrail::Model::InstanceMethods

          actions << :deleted_records
        end
      end
    end
  end
end
ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::PaperTrail::PaperTrailBridge
