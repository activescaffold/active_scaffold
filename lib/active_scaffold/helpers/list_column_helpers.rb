# frozen_string_literal: true

require 'active_scaffold/helpers/list_column_helpers/rendering'
require 'active_scaffold/helpers/list_column_helpers/formatting'
require 'active_scaffold/helpers/list_column_helpers/inplace_editing'
require 'active_scaffold/helpers/list_column_helpers/headings'
require 'active_scaffold/helpers/list_column_helpers/calculations'

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumnHelpers
      def list_record_view
        'list_record'
      end

      include Rendering
      include Formatting
      include InplaceEditing
      include Headings
      include Calculations
    end
  end
end
