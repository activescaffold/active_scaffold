# frozen_string_literal: true

module ActiveScaffold
  module TestSupport
    module Javascript
      module Routes
        PATH = '/active_scaffold/javascript_test/:id'

        class << self
          def install!
            routes = Rails.application.routes
            return if installed?(routes)

            block = proc do
              get PATH, to: ActiveScaffold::TestSupport::Javascript::FixtureController.action(:show),
                        as: :active_scaffold_javascript_test
            end
            if routes.instance_variable_get(:@finalized)
              routes.send(:eval_block, block)
            else
              routes.append(&block)
              routes.finalize!
            end
          end

          private

          def installed?(routes)
            routes.named_routes.key?(:active_scaffold_javascript_test)
          end
        end
      end
    end
  end
end
