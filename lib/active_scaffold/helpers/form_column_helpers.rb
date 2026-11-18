# frozen_string_literal: true

require 'active_scaffold/helpers/form_column_helpers/inputs'
require 'active_scaffold/helpers/form_column_helpers/rendering'
require 'active_scaffold/helpers/form_column_helpers/subforms'
require 'active_scaffold/helpers/form_column_helpers/numerical_constraints'

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      include Inputs
      include Rendering
      include Subforms
      include NumericalConstraints
    end
  end
end
